# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
{
  nclib ? import ../utils/lib.nix
  , utils ? import ../utils
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

    pkgDefArgs = { this = thisPackage; inherit name luaPath pkgs mkPlugin mkNvimPlugin; };

    thisPackage = packageDefinitions.${name} pkgDefArgs;
    initial_settings = {
      wrapRc = true;
      extraName = "";
      configDirName = "nvim";
      wrappedCfgPath = null;
      unwrappedCfgPath = null;
      autowrapRuntimeDeps = "suffix";
      autoconfigure = "prefix";
      autoPluginDeps = true;
      aliases = null;
      nvimSRC = null;
      neovim-unwrapped = null;
      useBinaryWrapper = false;
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
    final_cat_defs_set = (base_sections // (categoryDefinitions {
      # categories depends on extraCats
      inherit categories pkgs name mkPlugin mkNvimPlugin;
      settings = initial_settings;
      extra = extraTableLua;
    }));
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

    # the following 4 take an initial section name argument for error messages

    # returns a function that returns a list
    combineCatsOfFuncs = sorting.combineCatsOfFuncs categories;

    # returns a list of wrapper args
    filterAndFlattenEnvVars = sorting.filterAndFlattenEnvVars categories;

    # returns a list of wrapper args
    filterAndFlattenWrapArgs = sorting.filterAndFlattenWrapArgs categories;

    # returns a string of unescaped wrapper args
    filterAndFlattenXtraWrapArgs = sorting.filterAndFlattenXtraWrapArgs categories;

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
      settings = initial_settings;
      inherit nclib final_cat_defs_set combineCatsOfFuncs
        filterAndFlattenEnvVars filterAndFlattenWrapArgs filterAndFlattenXtraWrapArgs;
    };

    # replace the path functions with lua before trying to write a nix function to a lua file
    settings = host_builder.final_settings;

    # see :help nixCats
    # this function gets passed all the way into the wrapper so that we can also add
    # other dependencies that get resolved later in the process such as treesitter grammars.
    nixCats = allPluginDeps: let
      wrappedCfgPath = if pkgs.lib.isFunction settings.wrappedCfgPath then settings.wrappedCfgPath pkgDefArgs else settings.wrappedCfgPath;
      fcfg = if wrappedCfgPath != null then wrappedCfgPath else luaPath;
      nixCats_config_location = if builtins.isString settings.wrapRc
        then utils.n2l.types.inline-unsafe.mk {
            body = ''not os.getenv(${utils.n2l.uglyLua settings.wrapRc}) and ${utils.n2l.uglyLua fcfg} or '' + (
              if settings.unwrappedCfgPath == null
              then "vim.fn.stdpath('config')"
              else utils.n2l.uglyLua settings.unwrappedCfgPath
            );
          }
        else if settings.wrapRc == true then fcfg
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
        inherit nixCats_config_location wrappedCfgPath;
      };
    in pkgs.runCommandNoCC "nixCats-plugin-${name}" {
      src = pkgs.replaceVars ./nixCats.lua {
        nixCatsPawsible = utils.n2l.toLua allPluginDeps;
        nixCatsExtra = utils.n2l.toLua extraTableLua;
        nixCatsCats = utils.n2l.toLua categoriesPlus;
        nixCatsSettings = utils.n2l.toLua settingsPlus;
        nixCatsPetShop = utils.n2l.toLua (sorting.getCatSpace {
          inherit categories final_cat_defs_set;
          sections = pkgs.lib.mapAttrsToList (n: _: [ n ]) base_sections ++ host_builder.new_sections;
        });
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
          if vim.fn.filereadable(nixCats.configDir .. "/init.lua") == 1 then
            dofile(nixCats.configDir .. "/init.lua")
          elseif vim.fn.filereadable(nixCats.configDir .. "/init.vim") == 1 then
            vim.cmd.source(nixCats.configDir .. "/init.vim")
          end
          -- all other lua from nix plugin specs
          ${normalized.inlineConfigs}
          -- optionalLuaAdditions
          ${optLua.post}
          ${pkgs.lib.optionalString (settings.autoconfigure == "suffix") normalized.passthru_initLua}'';
      };
    } ''
      mkdir -p $out/doc
      cp -r ${../nixCatsHelp}/* $out/doc/
      mkdir -p $out/lua/nixCats
      cp -r ${./nixCats}/* $out/lua/nixCats
      cp $src $out/lua/nixCats.lua
    '';
  in {
    inherit pkgs;
    useBinaryWrapper = settings.useBinaryWrapper == true;
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
      bashBeforeWrapper = if settings.useBinaryWrapper == true then []
        else if builtins.isString bashBeforeWrapper then [bashBeforeWrapper]
        else filterAndFlattenXtraWrapArgs "bashBeforeWrapper" bashBeforeWrapper;
      extraMakeWrapperArgs = filterAndFlattenXtraWrapArgs "extraWrapperArgs" extraWrapperArgs;
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
      customAliases = pkgs.lib.unique (pkgs.lib.optionals (builtins.isList settings.aliases) settings.aliases);
    };
  };

  main_builder = args: let
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
    final_processed = process_args {
      inherit (finalAttrs.passthru) categoryDefinitions packageDefinitions luaPath;
      name = finalAttrs.passthru.nixCats_packageName;
      inherit (processed) pkgs;
    };
  in {
    inherit (final_processed.drvargs) name meta buildPhase bashBeforeWrapper setupLua manifestLua; # <- generated args
    passAsFile = [ "setupLua" "manifestLua" ] ++ (if final_processed.useBinaryWrapper then [] else [ "bashBeforeWrapper" ]);
    nativeBuildInputs = [
      (if final_processed.useBinaryWrapper then processed.pkgs.makeBinaryWrapper else processed.pkgs.makeWrapper)
    ];
    preferLocalBuild = true; # <- set here plain so that it is overrideable
    dontUnpack = true;
    passthru = processed.pass // {
      inherit (final_processed.pass) moduleNamespace homeModule nixosModule keepLuaBuilder; # <- generated passthru
      dependencyOverlays = builtins.seq final_processed.pass.dependencyOverlays processed.pass.dependencyOverlays;
      extra_pkg_config = builtins.seq final_processed.pass.extra_pkg_config processed.pass.extra_pkg_config;
      extra_pkg_params = builtins.seq final_processed.pass.extra_pkg_params processed.pass.extra_pkg_params;
    };
  });

in luaPath: pkgsParams: categoryDefinitions: packageDefinitions: name: let
  nixpkgspath = pkgsParams.pkgs.path
    or pkgsParams.nixpkgs.path
    or pkgsParams.nixpkgs.outPath
    or pkgsParams.nixpkgs
    or (if builtins ? system then <nixpkgs> else (import ./errors.nix).main);
  newlib = pkgsParams.pkgs.lib or pkgsParams.nixpkgs.lib or (import "${nixpkgspath}/lib");
  mkOverride = nclib.makeOverridable newlib.overrideDerivation;
  system = pkgsParams.system or pkgsParams.pkgs.system or pkgsParams.nixpkgs.system or builtins.system or (import ./errors.nix).main;
in
mkOverride main_builder {
  inherit system luaPath categoryDefinitions packageDefinitions name;
  nixCats_passthru = pkgsParams.nixCats_passthru or {};
  extra_pkg_config = pkgsParams.extra_pkg_config or {};
  extra_pkg_params = pkgsParams.extra_pkg_params or {};
  pkgs = pkgsParams.pkgs or null;
  nixpkgs = if pkgsParams ? "pkgs" && pkgsParams.pkgs != null
    then pkgsParams.pkgs // { outPath = nixpkgspath;}
    else if pkgsParams.nixpkgs ? "lib"
      then pkgsParams.nixpkgs
      else { outPath = nixpkgspath; lib = newlib; };
  dependencyOverlays = pkgsParams.dependencyOverlays or [];
}
