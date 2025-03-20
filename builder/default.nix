# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
{
  nclib
  , utils
}: let
  process_args = { luaPath
  , categoryDefinitions
  , packageDefinitions
  , name
  , ...
  }@args:
    assert with builtins; !(isFunction categoryDefinitions && isAttrs packageDefinitions && isString name && isAttrs (args.nixCats_passthru or {})
      && (isPath luaPath || (isString luaPath && hasContext luaPath) || luaPath.outPath or null != null)) -> import ./builder_error.nix;
  let
    system = let
      val = args.system or args.pkgs.system or args.nixpkgs.system or builtins.system or (import ./builder_error.nix);
    in if builtins.isString val then val else import ./builder_error.nix;
    extra_pkg_config = if ! (builtins.isAttrs args.extra_pkg_config or {})
      then import ./builder_error.nix
      else args.extra_pkg_config or {};
    extra_pkg_params = if ! (builtins.isAttrs args.extra_pkg_params or {})
      then import ./builder_error.nix
      else args.extra_pkg_params or {};

    pkgs = with builtins; (let
      overlays = if isList (args.dependencyOverlays or null)
        then args.dependencyOverlays
        else if nclib.ncIsAttrs (args.dependencyOverlays or null)
        then builtins.trace ''
          # NixCats deprecation warning
          Do not wrap your dependencyOverlays list in a set of systems.
          They should just be a list.
          Use `utils.fixSystemizedOverlay` if required to fix occasional malformed flake overlay outputs
          See :h nixCats.flake.outputs.getOverlays
          '' args.dependencyOverlays.${system}
        else [];
    in if (args.pkgs or null) != null && extra_pkg_config == {} && extra_pkg_params == {} && (args.pkgs.system or null) == system
      then if overlays == [] then args.pkgs else args.pkgs.appendOverlays overlays
      else import (args.pkgs.path or args.nixpkgs.path or args.nixpkgs.outPath or args.nixpkgs) ({
          inherit system;
          config = (args.pkgs.config or {}) // extra_pkg_config;
          overlays = (args.pkgs.overlays or []) ++ overlays;
        } // (args.extra_pkg_params or {})));

    mkNvimPlugin = src: pname:
      pkgs.vimUtils.buildVimPlugin {
        inherit pname src;
        doCheck = false;
        version = builtins.toString (src.lastModifiedDate or "master");
      };

    ncTools = pkgs.callPackage ./ncTools.nix { inherit nclib; };

    thisPackage = packageDefinitions.${name} { inherit pkgs mkNvimPlugin; };
    settings = {
      wrapRc = true;
      viAlias = false;
      vimAlias = false;
      withNodeJs = false;
      withRuby = true;
      gem_path = null;
      withPerl = false;
      extraName = "";
      withPython3 = true;
      configDirName = "nvim";
      unwrappedCfgPath = null;
      autowrapRuntimeDeps = "suffix";
      autoconfigure = "prefix";
      aliases = null;
      nvimSRC = null;
      neovim-unwrapped = null;
      suffix-path = false;
      suffix-LD = false;
      disablePythonSafePath = false;
      disablePythonPath = true; # <- you almost certainly want this set to true
      collate_grammars = true;
      moduleNamespace = [ name ];
    } // (thisPackage.settings or {});

    final_cat_defs_set = ({
      startupPlugins = {};
      optionalPlugins = {};
      lspsAndRuntimeDeps = {};
      sharedLibraries = {};
      propagatedBuildInputs = {};
      environmentVariables = {};
      extraWrapperArgs = {};
      /* the function you would have passed to python.withPackages */
      extraPython3Packages = {};
      extraPython3wrapperArgs = {};
    # same thing except for lua.withPackages
      extraLuaPackages = {};
    # only for use when importing flake in a flake 
    # and need to only add a bit of lua for an added plugin
      optionalLuaAdditions = {};
      optionalLuaPreInit = {};
      bashBeforeWrapper = {};
      # set of lists of lists of strings of other categories to enable
      extraCats = {};
    } // (categoryDefinitions {
      # categories depends on extraCats
      inherit categories settings pkgs name mkNvimPlugin;
      extra = extraTableLua;
    }));
    inherit (final_cat_defs_set)
    startupPlugins optionalPlugins lspsAndRuntimeDeps
    propagatedBuildInputs environmentVariables
    extraWrapperArgs extraPython3Packages
    extraLuaPackages optionalLuaAdditions
    extraPython3wrapperArgs sharedLibraries
    optionalLuaPreInit bashBeforeWrapper;

    categories = ncTools.applyExtraCats (thisPackage.categories or {}) final_cat_defs_set.extraCats;
    extraTableLua = thisPackage.extra or {};
    all_cat_names = ncTools.getCatSpace (builtins.attrValues final_cat_defs_set);

    # this is what allows for dynamic packaging in flake.nix
    # It includes categories marked as true, then flattens to a single list
    filterAndFlatten = ncTools.filterAndFlatten categories;
    # This one filters and flattens like above but for attrs of attrs 
    # and then maps name and value
    # into a list based on the function we provide it.
    # its like a flatmap function but with a built in filter for category.
    filterAndFlattenMapInnerAttrs = ncTools.filterAndFlattenMapInnerAttrs categories;

    # shorthand to reduce lispyness
    filterFlattenUnique = s: pkgs.lib.unique (filterAndFlatten s);

    # extraPythonPackages and the like require FUNCTIONS that return lists.
    # so we make a function that returns a function that returns lists.
    # this is used for the fields in the wrapper where the default value is (_: [])
    combineCatsOfFuncs = section:
      x: pkgs.lib.pipe section [
        filterAndFlatten
        (map (value: value x))
        pkgs.lib.flatten
        pkgs.lib.unique
      ];

    # see :help nixCats
    # this function gets passed all the way into the wrapper so that we can also add
    # other dependencies that get resolved later in the process such as treesitter grammars.
    nixCats = allPluginDeps: let
      nixCats_config_location = if settings.wrapRc == true then luaPath
        else if settings.unwrappedCfgPath == null
          then utils.n2l.types.inline-unsafe.mk { body = ''vim.fn.stdpath("config")''; }
        else settings.unwrappedCfgPath;

      categoriesPlus = categories // {
        nixCats_wrapRc = settings.wrapRc;
        nixCats_packageName = name;
        inherit nixCats_config_location;
      };
      settingsPlus = settings // {
        nixCats_packageName = name;
        inherit nixCats_config_location;
      };

      cats = ncTools.mkLuaFileWithMeta "cats.lua" categoriesPlus;
      settingsTable = ncTools.mkLuaFileWithMeta "settings.lua" settingsPlus;
      petShop = ncTools.mkLuaFileWithMeta "petShop.lua" all_cat_names;
      depsTable = ncTools.mkLuaFileWithMeta "pawsible.lua" allPluginDeps;
      extraItems = ncTools.mkLuaFileWithMeta "extra.lua" extraTableLua;
    in pkgs.stdenv.mkDerivation {
      name = "nixCats";
      builder = pkgs.writeText "builder.sh" /*bash*/ ''
        source $stdenv/setup
        mkdir -p $out/lua/nixCats
        mkdir -p $out/doc
        cp ${./nixCats.lua} $out/lua/nixCats/init.lua
        cp ${./nixCatsMeta.lua} $out/lua/nixCats/meta.lua
        cp ${cats} $out/lua/nixCats/cats.lua
        cp ${settingsTable} $out/lua/nixCats/settings.lua
        cp ${depsTable} $out/lua/nixCats/pawsible.lua
        cp ${petShop} $out/lua/nixCats/petShop.lua
        cp ${extraItems} $out/lua/nixCats/extra.lua
        cp -r ${../nixCatsHelp}/* $out/doc/
      '';
    };

    buildInputs = filterFlattenUnique propagatedBuildInputs;

    normalized = pkgs.callPackage ./normalizePlugins.nix {
      startup = filterAndFlatten startupPlugins;
      optional = filterAndFlatten optionalPlugins;
      inherit (utils) n2l;
    };

    customRC = let
      optLuaPre = if builtins.isString optionalLuaPreInit
        then optionalLuaPreInit
        else builtins.concatStringsSep "\n"
        (filterFlattenUnique optionalLuaPreInit);
      optLuaAdditions = if builtins.isString optionalLuaAdditions
        then optionalLuaAdditions
        else builtins.concatStringsSep "\n"
        (filterFlattenUnique optionalLuaAdditions);
    in /*lua*/''
      ${pkgs.lib.optionalString (settings.autoconfigure == "prefix" || settings.autoconfigure == true) normalized.passthru_initLua}
      -- optionalLuaPreInit
      ${optLuaPre}
      -- lua from nix with pre = true
      ${normalized.preInlineConfigs}
      -- run the init.lua (or init.vim)
      if vim.fn.filereadable(require('nixCats').configDir .. "/init.lua") == 1 then
        dofile(require('nixCats').configDir .. "/init.lua")
      elseif vim.fn.filereadable(require('nixCats').configDir .. "/init.vim") == 1 then
        vim.cmd.source(require('nixCats').configDir .. "/init.vim")
      end
      -- all other lua from nix plugin specs
      ${normalized.inlineConfigs}
      -- optionalLuaAdditions
      ${optLuaAdditions}
      ${pkgs.lib.optionalString (settings.autoconfigure == "suffix") normalized.passthru_initLua}
    '';

    # cat our args
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
    extraMakeWrapperArgs = let 
      preORpostPATH = if settings.suffix-path then "--suffix" else "--prefix";
      userPathEnv = filterFlattenUnique lspsAndRuntimeDeps;
      preORpostLD = if settings.suffix-LD then "--suffix" else "--prefix";
      userLinkables = filterFlattenUnique sharedLibraries;
      userWrapperArgs = filterFlattenUnique extraWrapperArgs;
      userEnvVars = pkgs.lib.pipe environmentVariables [
        (filterAndFlattenMapInnerAttrs (name: value: [ [ "--set" name value ] ]))
        pkgs.lib.unique
        builtins.concatLists
      ];
    in pkgs.lib.escapeShellArgs (pkgs.lib.optionals 
        (settings.configDirName != null && settings.configDirName != "" || settings.configDirName != "nvim") [
        "--set" "NVIM_APPNAME" settings.configDirName # this sets the name of the folder to look for nvim stuff in
      ] ++ pkgs.lib.optionals (userPathEnv != []) [
        preORpostPATH "PATH" ":" (pkgs.lib.makeBinPath userPathEnv)
      ] ++ pkgs.lib.optionals (userLinkables != []) [
        preORpostLD "LD_LIBRARY_PATH" ":" (pkgs.lib.makeLibraryPath userLinkables)
      ] ++ userEnvVars) + " " + builtins.concatStringsSep " " userWrapperArgs;

    python3wrapperArgs = pkgs.lib.pipe extraPython3wrapperArgs [
      filterAndFlatten
      (wargs: pkgs.lib.optionals settings.disablePythonPath ["--unset PYTHONPATH"]
        ++ pkgs.lib.optionals settings.disablePythonSafePath ["--unset PYTHONSAFEPATH"]
        ++ wargs)
      pkgs.lib.unique
      (builtins.concatStringsSep " ")
    ];

    preWrapperShellCode = let
      xtra = /*bash*/''
        NVIM_WRAPPER_PATH_NIX="$(${pkgs.coreutils}/bin/readlink -f "$0")"
        export NVIM_WRAPPER_PATH_NIX
      '';
    in if builtins.isString bashBeforeWrapper
      then xtra + "\n" + bashBeforeWrapper
      else builtins.concatStringsSep "\n" ([xtra] ++ (filterFlattenUnique bashBeforeWrapper));

    # add our propagated build dependencies
    baseNvimUnwrapped = if settings.neovim-unwrapped == null then pkgs.neovim-unwrapped else settings.neovim-unwrapped;
    myNeovimUnwrapped = if settings.nvimSRC != null || buildInputs != [] then baseNvimUnwrapped.overrideAttrs (prev: {
      src = if settings.nvimSRC != null then settings.nvimSRC else prev.src;
      propagatedBuildInputs = buildInputs ++ (prev.propagatedBuildInputs or []);
    }) else baseNvimUnwrapped;

    nc_passthru = (args.nixCats_passthru or {}) // {
      keepLuaBuilder = utils.baseBuilder luaPath; # why is this still a thing?
      nixCats_packageName = name;
      inherit categoryDefinitions packageDefinitions luaPath utils extra_pkg_config extra_pkg_params;
      dependencyOverlays = pkgs.overlays or [];
      inherit (settings) moduleNamespace;
      # export nixos module based on this package
      nixosModule = utils.mkNixosModules {
        defaultPackageName = name;
        dependencyOverlays = pkgs.overlays or [];
        inherit luaPath extra_pkg_config extra_pkg_params
          categoryDefinitions packageDefinitions;
        nixpkgs = args.nixpkgs or pkgs.path;
        inherit (settings) moduleNamespace;
      };
      # and the same for home manager
      homeModule = utils.mkHomeModules {
        defaultPackageName = name;
        dependencyOverlays = pkgs.overlays or [];
        inherit luaPath extra_pkg_config extra_pkg_params
          categoryDefinitions packageDefinitions;
        nixpkgs = args.nixpkgs or pkgs.path;
        inherit (settings) moduleNamespace;
      };
    };
  in {
    pass = nc_passthru;
    inherit pkgs;
    drvargs = import ./wrapNeovim.nix {
      neovim-unwrapped = myNeovimUnwrapped;
      nixCats_packageName = name;
      inherit pkgs extraMakeWrapperArgs nixCats ncTools preWrapperShellCode customRC;
      inherit (settings) vimAlias viAlias withRuby withPython3 withPerl extraName withNodeJs aliases gem_path collate_grammars autowrapRuntimeDeps;
      inherit (normalized) start opt;
        /* the function you would have passed to python.withPackages */
      # extraPythonPackages = combineCatsOfFuncs extraPythonPackages;
        /* the function you would have passed to python.withPackages */
      extraPython3Packages = combineCatsOfFuncs extraPython3Packages;
      extraPython3wrapperArgs = python3wrapperArgs;
        /* the function you would have passed to lua.withPackages */
      extraLuaPackages = combineCatsOfFuncs extraLuaPackages;
    };
  };

  mkFinal = args: let
    # separate function to process the spec from making the drv
    # this function is the entrypoint, and the function that creates the final drv
    # process_args will return the set that you would pass to mkDerivation
    # along with passthru and its pkgs separately
    # Doing it this way allows for using overrideAttrs to change the following args
    # passthru.{ categoryDefinitions, packageDefinitions, luaPath, nixCats_packageName }
    # in order to affect the final derivation via the nixCats wrapper via overrideAttrs
    # This, in combination with how we process pkgsParams, also allows us to not
    # reimport nixpkgs multiple times while doing this.
    processed = process_args args;
  in processed.pkgs.stdenv.mkDerivation (finalAttrs: let
    oldargs = {
      inherit (finalAttrs.passthru) categoryDefinitions packageDefinitions luaPath;
      name = finalAttrs.passthru.nixCats_packageName;
      inherit (processed) pkgs;
    };
    final_processed = process_args oldargs;
  in {
    inherit (final_processed.drvargs) name meta nativeBuildInputs buildPhase __structuredAttrs dontUnpack preferLocalBuild;
    passthru = processed.pass // {
      inherit (final_processed.pass) moduleNamespace homeModule nixosModule keepLuaBuilder;
      dependencyOverlays = builtins.seq final_processed.pass.dependencyOverlays processed.pass.dependencyOverlays;
      extra_pkg_config = builtins.seq final_processed.pass.extra_pkg_config processed.pass.extra_pkg_config;
      extra_pkg_params = builtins.seq final_processed.pass.extra_pkg_params processed.pass.extra_pkg_params;
    };
  });
in mkFinal
