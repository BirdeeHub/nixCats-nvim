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
      && (isPath luaPath || (isString luaPath && hasContext luaPath) || luaPath.outPath or null != null)) -> (import ./errors.nix).main;
  let
    system = let
      val = args.system or args.pkgs.system or args.nixpkgs.system or builtins.system or (import ./errors.nix).main;
    in if builtins.isString val then val else (import ./errors.nix).main;
    extra_pkg_config = if ! (builtins.isAttrs args.extra_pkg_config or {})
      then (import ./errors.nix).main
      else args.extra_pkg_config or {};
    extra_pkg_params = if ! (builtins.isAttrs args.extra_pkg_params or {})
      then (import ./errors.nix).main
      else args.extra_pkg_params or {};

    pkgs = with builtins; (let
      overlays = if isList (args.dependencyOverlays or null)
        then args.dependencyOverlays
        else if nclib.ncIsAttrs (args.dependencyOverlays or null)
        then nclib.warnfn ''
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

    mkPlugin = pname: src:
      pkgs.vimUtils.buildVimPlugin {
        inherit pname src;
        doCheck = false;
        version = builtins.toString (src.lastModifiedDate or "master");
      };
    mkNvimPlugin = pkgs.lib.flip mkPlugin;

    sorting = import ./sorting.nix { inherit (pkgs) lib; inherit nclib; };

    thisPackage = packageDefinitions.${name} { inherit name pkgs mkPlugin mkNvimPlugin; };
    initial_settings = {
      wrapRc = true;
      extraName = "";
      configDirName = "nvim";
      unwrappedCfgPath = null;
      autowrapRuntimeDeps = "suffix";
      autoconfigure = "prefix";
      autoPluginDeps = true;
      aliases = null;
      nvimSRC = null;
      neovim-unwrapped = null;
      suffix-path = true;
      suffix-LD = true;
      collate_grammars = true;
      moduleNamespace = [ name ];
      hosts = {};
    } // (thisPackage.settings or {});

    base_sections = {
      startupPlugins = {};
      optionalPlugins = {};
      lspsAndRuntimeDeps = {};
      sharedLibraries = {};
      propagatedBuildInputs = {};
      environmentVariables = {};
      extraWrapperArgs = {};
      wrapperArgs = {};
    # same thing except for lua.withPackages
      extraLuaPackages = {};
    # only for use when importing flake in a flake 
    # and need to only add a bit of lua for an added plugin
      optionalLuaAdditions = {};
      optionalLuaPreInit = {};
      bashBeforeWrapper = {};
      # set of lists of lists of strings of other categories to enable
      extraCats = {};
    };
    final_cat_defs_set = (base_sections // (let
      catdef = categoryDefinitions {
        # categories depends on extraCats
        inherit categories pkgs name mkPlugin mkNvimPlugin;
        settings = initial_settings;
        extra = extraTableLua;
      };
    catdef_with_deprecations = catdef
      // (pkgs.lib.optionalAttrs (catdef ? extraPython3Packages) (nclib.warnfn ''
        nixCats categoryDefinitions extraPython3Packages section deprecated for python3.libraries
      '' { python3.libraries = catdef.extraPython3Packages; }))
      // (pkgs.lib.optionalAttrs (catdef ? extraPython3wrapperArgs) (nclib.warnfn ''
        nixCats categoryDefinitions extraPython3wrapperArgs section deprecated for python3.extraWrapperArgs
      '' { python3.extraWrapperArgs = catdef.extraPython3wrapperArgs; }));
    in catdef_with_deprecations));
    # categories depends on extraCats
    categories = sorting.applyExtraCats (thisPackage.categories or {}) final_cat_defs_set.extraCats;
    extraTableLua = thisPackage.extra or {};
    inherit (final_cat_defs_set)
    startupPlugins optionalPlugins lspsAndRuntimeDeps
    propagatedBuildInputs environmentVariables sharedLibraries
    extraWrapperArgs extraLuaPackages optionalLuaAdditions
    optionalLuaPreInit bashBeforeWrapper wrapperArgs;

    # this is what allows for dynamic packaging in flake.nix
    # It includes categories marked as true, then flattens to a single list
    filterAndFlatten = sorting.filterAndFlatten categories;

    # shorthand to reduce lispyness
    filterFlattenUnique = s: pkgs.lib.unique (filterAndFlatten s);

    # the following 3 take an initial section name argument for error messages

    # returns a function that returns a list
    combineCatsOfFuncs = sorting.combineCatsOfFuncs categories;

    # returns a list of wrapper args
    filterAndFlattenEnvVars = sorting.filterAndFlattenEnvVars categories;

    # returns a list of wrapper args
    filterAndFlattenWrapArgs = sorting.filterAndFlattenWrapArgs categories;

    normalized = import ./normalizePlugins.nix {
      startup = filterAndFlatten startupPlugins;
      optional = filterAndFlatten optionalPlugins;
      inherit (initial_settings) autoPluginDeps;
      inherit (pkgs) lib;
      inherit nclib;
    };

    host_builder = pkgs.callPackage ./hosts.nix {
      plugins = normalized.start ++ normalized.opt;
      invalidHostNames = builtins.attrNames base_sections;
      nixCats_packageName = name;
      inherit nclib initial_settings final_cat_defs_set;
      inherit combineCatsOfFuncs filterAndFlattenEnvVars filterAndFlattenWrapArgs filterFlattenUnique;
    };

    # replace the path functions with lua before trying to write a nix function to a lua file
    settings = host_builder.final_settings;

    # see :help nixCats
    # this function gets passed all the way into the wrapper so that we can also add
    # other dependencies that get resolved later in the process such as treesitter grammars.
    nixCats = allPluginDeps: let
      nixCats_config_location = if builtins.isString settings.wrapRc
        then utils.n2l.types.inline-unsafe.mk {
            body = ''not os.getenv(${utils.n2l.uglyLua settings.wrapRc}) and "${luaPath}" or '' + (
              if settings.unwrappedCfgPath == null
              then "vim.fn.stdpath('config')"
              else utils.n2l.uglyLua settings.unwrappedCfgPath
            );
          }
        else if settings.wrapRc == true then
          luaPath
        else if settings.unwrappedCfgPath == null then
          utils.n2l.types.inline-unsafe.mk { body = ''vim.fn.stdpath("config")''; }
        else settings.unwrappedCfgPath;

      finalwraprc = if builtins.isString settings.wrapRc
        then utils.n2l.types.inline-unsafe.mk { body = ''not os.getenv(${utils.n2l.uglyLua settings.wrapRc})''; }
        else settings.wrapRc;

      categoriesPlus = categories // {
        nixCats_wrapRc = finalwraprc;
        nixCats_packageName = name;
        inherit nixCats_config_location;
      };
      settingsPlus = settings // {
        wrapRc = finalwraprc;
        nixCats_packageName = name;
        inherit nixCats_config_location;
      };

      nixCatsCats = utils.n2l.toLua categoriesPlus;
      nixCatsSettings = utils.n2l.toLua settingsPlus;
      nixCatsPetShop = utils.n2l.toLua (sorting.getCatSpace final_cat_defs_set);
      nixCatsPawsible = utils.n2l.toLua allPluginDeps;
      nixCatsExtra = utils.n2l.toLua extraTableLua;
      nixCatsInitMain = let
        processExtraLua = with builtins; field: section: if isString section then section else pkgs.lib.pipe section [
          filterFlattenUnique
          (map (x: if isString x then { config = x; priority = 150; } else x // { priority = x.priority or 150; }))
          (sort (a: b: a.priority < b.priority))
          (map (v: v.config or ((import ./errors.nix).optLua field)))
          (concatStringsSep "\n")
        ];
        optLua = {
          pre = processExtraLua "optionalLuaPreInit" optionalLuaPreInit;
          post = processExtraLua "optionalLuaAdditions" optionalLuaAdditions;
        };
      in /*lua*/''
        ${pkgs.lib.optionalString (settings.autoconfigure == "prefix" || settings.autoconfigure == true) normalized.passthru_initLua}
        -- optionalLuaPreInit
        ${optLua.pre}
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
        ${optLua.post}
        ${pkgs.lib.optionalString (settings.autoconfigure == "suffix") normalized.passthru_initLua}'';

    in pkgs.runCommandNoCC "nixCats-plugin-${name}" {
      src = pkgs.substituteAll {
        src = ./nixCats/init.lua;
        inherit nixCatsSettings nixCatsCats nixCatsPetShop nixCatsPawsible nixCatsExtra nixCatsInitMain;
      };
    } ''
      mkdir -p $out/doc
      cp -r ${../nixCatsHelp}/* $out/doc/
      mkdir -p $out/lua/nixCats
      cp ${./nixCats/meta.lua} $out/lua/nixCats/meta.lua
      cp $src $out/lua/nixCats/init.lua
    '';
  in {
    inherit pkgs;
    pass = (args.nixCats_passthru or {}) // {
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
    drvargs = import ./wrapNeovim.nix {
      nixCats_packageName = name;
      inherit pkgs nixCats nclib;
      inherit (settings) extraName aliases collate_grammars autowrapRuntimeDeps configDirName;
      inherit (host_builder) host_phase nvim_host_args nvim_host_vars;
      inherit (normalized) start opt;
      preORpostPATH = if settings.suffix-path then "--suffix" else "--prefix";
      userPathEnv = filterFlattenUnique lspsAndRuntimeDeps;
      preORpostLD = if settings.suffix-LD then "--suffix" else "--prefix";
      userLinkables = filterFlattenUnique sharedLibraries;
      userEnvVars = filterAndFlattenEnvVars "environmentVariables" environmentVariables;
      makeWrapperArgs = filterAndFlattenWrapArgs "wrapperArgs" wrapperArgs;
      bashBeforeWrapper = if builtins.isString bashBeforeWrapper
        then [bashBeforeWrapper] else filterFlattenUnique bashBeforeWrapper;
      extraMakeWrapperArgs = builtins.concatStringsSep " " (filterFlattenUnique extraWrapperArgs);
      # the function you would have passed to lua.withPackages
      extraLuaPackages = combineCatsOfFuncs "lua" extraLuaPackages;
      # add our propagated build dependencies (not adviseable as then you miss the cache)
      # can also be done by overriding nvim itself via settings.neovim-unwrapped
      # as such, more sections that do this will not be added.
      neovim-unwrapped = let
        buildInputs = filterFlattenUnique propagatedBuildInputs;
        baseNvimUnwrapped = if settings.neovim-unwrapped == null then pkgs.neovim-unwrapped else settings.neovim-unwrapped;
      in if settings.nvimSRC == null && buildInputs == [] then baseNvimUnwrapped
        else baseNvimUnwrapped.overrideAttrs (prev: {
        src = if settings.nvimSRC != null then settings.nvimSRC else prev.src;
        propagatedBuildInputs = buildInputs ++ (prev.propagatedBuildInputs or []);
      });
      customAliases = let
        viAlias = if settings ? viAlias then nclib.warnfn ''
          nixCats: settings.viAlias is being deprecated
          use aliases = [ "vi" ]; instead.
        '' settings.viAlias else false;
        vimAlias = if settings ? vimAlias then nclib.warnfn ''
          nixCats: settings.vimAlias is being deprecated
          use aliases = [ "vim" ]; instead.
        '' settings.vimAlias else false;
      in pkgs.lib.unique (
        pkgs.lib.optional viAlias "vi"
        ++ pkgs.lib.optional vimAlias "vim"
        ++ pkgs.lib.optionals (builtins.isList settings.aliases) settings.aliases
      );
    };
  };

in args: let
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
  inherit (final_processed.drvargs) name meta buildPhase bashBeforeWrapper; # <- generated args
  passAsFile = [ "bashBeforeWrapper" ];
  nativeBuildInputs = [ processed.pkgs.makeWrapper ]; # <- set here plain so that it is overrideable
  preferLocalBuild = true; # <- set here plain so that it is overrideable
  dontUnpack = true;
  passthru = processed.pass // {
    inherit (final_processed.pass) moduleNamespace homeModule nixosModule keepLuaBuilder; # <- generated passthru
    dependencyOverlays = builtins.seq final_processed.pass.dependencyOverlays processed.pass.dependencyOverlays;
    extra_pkg_config = builtins.seq final_processed.pass.extra_pkg_config processed.pass.extra_pkg_config;
    extra_pkg_params = builtins.seq final_processed.pass.extra_pkg_params processed.pass.extra_pkg_params;
  };
})
