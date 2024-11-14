# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
{ luaPath
, categoryDefinitions
, packageDefinitions
, name
, nixpkgs
, system ? (nixpkgs.system or import ./builder_error.nix)
, extra_pkg_config ? {}
, dependencyOverlays ? null
, nixCats_passthru ? {}
}:
let
  pkgs = with builtins; let
    config = if ! (isAttrs extra_pkg_config) then import ./builder_error.nix
      else (nixpkgs.config or {}) // extra_pkg_config;
    overlays = if isList dependencyOverlays
      then dependencyOverlays
      else dependencyOverlays.${system} or [];
  in if isAttrs nixCats_passthru && isFunction categoryDefinitions
    && isAttrs packageDefinitions && isString name
  then import (nixpkgs.path or nixpkgs.outPath or nixpkgs)
    { inherit system config overlays; }
  else import ./builder_error.nix;

  ncTools = pkgs.callPackage ./ncTools.nix { };
  thisPackage = packageDefinitions.${name} { inherit pkgs; };
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
    aliases = null;
    nvimSRC = null;
    neovim-unwrapped = null;
    suffix-path = false;
    suffix-LD = false;
    disablePythonSafePath = false;
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
    inherit categories settings pkgs name;
  }));
  inherit (final_cat_defs_set)
  startupPlugins optionalPlugins lspsAndRuntimeDeps
  propagatedBuildInputs environmentVariables
  extraWrapperArgs extraPython3Packages
  extraLuaPackages optionalLuaAdditions
  extraPython3wrapperArgs sharedLibraries
  optionalLuaPreInit bashBeforeWrapper;

  categories = ncTools.applyExtraCats (thisPackage.categories or {}) final_cat_defs_set.extraCats;

in
  let
    # copy entire flake to store directory
    LuaConfig = pkgs.stdenv.mkDerivation {
      name = "nixCats-special-rtp-entry-LuaConfig";
      builder = pkgs.writeText "builder.sh" /* bash */ ''
        source $stdenv/setup
        mkdir -p $out
        cp -r ${luaPath}/* $out/
      '';
    };

    # see :help nixCats
    # this function gets passed all the way into the wrapper so that we can also add
    # other dependencies that get resolved later in the process such as treesitter grammars.
    nixCats = allPluginDeps: pkgs.stdenv.mkDerivation (let
      isUnwrappedCfgPath = settings.wrapRc == false && builtins.isString settings.unwrappedCfgPath;
      isStdCfgPath = settings.wrapRc == false && ! builtins.isString settings.unwrappedCfgPath;

      nixCats_config_location = if isUnwrappedCfgPath then "${settings.unwrappedCfgPath}"
        else if isStdCfgPath then ncTools.types.inline-unsafe.mk { body = ''vim.fn.stdpath("config")''; }
        else "${LuaConfig}";

      categoriesPlus = categories // {
        nixCats_wrapRc = settings.wrapRc;
        nixCats_packageName = name;
        inherit nixCats_config_location;
      };
      settingsPlus = settings // {
        nixCats_packageName = name;
        inherit nixCats_config_location;
      };
      all_def_names = ncTools.getCatSpace (builtins.attrValues final_cat_defs_set);

      cats = ncTools.mkLuaFileWithMeta "cats" categoriesPlus;
      settingsTable = ncTools.mkLuaFileWithMeta "settings" settingsPlus;
      petShop = ncTools.mkLuaFileWithMeta "petShop" all_def_names;
      depsTable = ncTools.mkLuaFileWithMeta "pawsible" allPluginDeps;
      extraItems = ncTools.mkLuaFileWithMeta "extra" (thisPackage.extra or {});
    in {
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
    });

    customRC = let
      optLuaPre = let
        lua = if builtins.isString optionalLuaPreInit
          then optionalLuaPreInit
          else builtins.concatStringsSep "\n"
          (pkgs.lib.unique (filterAndFlatten optionalLuaPreInit));
      in if lua != "" then "dofile([[${pkgs.writeText "optLuaPre.lua" lua}]])" else "";
      optLuaAdditions = let
        lua = if builtins.isString optionalLuaAdditions
          then optionalLuaAdditions
          else builtins.concatStringsSep "\n"
          (pkgs.lib.unique (filterAndFlatten optionalLuaAdditions));
      in if lua != "" then "dofile([[${pkgs.writeText "optLuaAdditions.lua" lua}]])" else "";
    in/*lua*/''
      ${optLuaPre}
      if vim.fn.filereadable(require('nixCats').configDir .. "/init.vim") == 1 then
        vim.cmd.source(require('nixCats').configDir .. "/init.vim")
      end
      if vim.fn.filereadable(require('nixCats').configDir .. "/init.lua") == 1 then
        dofile(require('nixCats').configDir .. "/init.lua")
      end
      ${optLuaAdditions}
    '';

    # this is what allows for dynamic packaging in flake.nix
    # It includes categories marked as true, then flattens to a single list
    filterAndFlatten = ncTools.filterAndFlatten categories;

    buildInputs = pkgs.lib.unique (filterAndFlatten propagatedBuildInputs);
    start = pkgs.lib.unique (filterAndFlatten startupPlugins);
    opt = pkgs.lib.unique (filterAndFlatten optionalPlugins);

    # For wrapperArgs:
    # This one filters and flattens like above but for attrs of attrs 
    # and then maps name and value
    # into a list based on the function we provide it.
    # its like a flatmap function but with a built in filter for category.
    filterAndFlattenMapInnerAttrs = ncTools.filterAndFlattenMapInnerAttrs categories;
    # This one filters and flattens attrs of lists and then maps value
    # into a list of strings based on the function we provide it.
    # it the same as above but for a mapping function with 1 argument
    # because the inner is a list not a set.
    filterAndFlattenMapInner = ncTools.filterAndFlattenMapInner categories;

    # and then applied to give us a 1 argument function:

    FandF_envVarSet = filterAndFlattenMapInnerAttrs 
          (name: value: ''--set ${name} "${value}"'');

    # extraPythonPackages and the like require FUNCTIONS that return lists.
    # so we make a function that returns a function that returns lists.
    # this is used for the fields in the wrapper where the default value is (_: [])
    combineCatsOfFuncs = section:
      (x: let
        appliedfunctions = filterAndFlattenMapInner (value: value x ) section;
        combinedFuncRes = builtins.concatLists appliedfunctions;
        uniquifiedList = pkgs.lib.unique combinedFuncRes;
      in
      uniquifiedList);

    # cat our args
    extraMakeWrapperArgs = let 
      linkables = pkgs.lib.unique (filterAndFlatten sharedLibraries);
      pathEnv = pkgs.lib.unique (filterAndFlatten lspsAndRuntimeDeps);
      preORpostPATH = if settings.suffix-path then "suffix" else "prefix";
      preORpostLD = if settings.suffix-LD then "suffix" else "prefix";
    in builtins.concatStringsSep " " (
      # this sets the name of the folder to look for nvim stuff in
      (if settings.configDirName != null
        && settings.configDirName != ""
        || settings.configDirName != "nvim"
        then [ ''--set NVIM_APPNAME "${settings.configDirName}"'' ] else [])
      # and these are our other now sorted args
      ++ (if pathEnv != [] 
            then [ ''--${preORpostPATH} PATH : "${pkgs.lib.makeBinPath pathEnv }"'' ]
          else [])
      ++ (if linkables != []
            then [ ''--${preORpostLD} LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath linkables }"'' ]
          else [])
      ++ (pkgs.lib.unique (FandF_envVarSet environmentVariables))
      ++ (pkgs.lib.unique (filterAndFlatten extraWrapperArgs))
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
    );

    python3wrapperArgs = pkgs.lib.unique ((filterAndFlatten extraPython3wrapperArgs) ++ (if settings.disablePythonSafePath then ["--unset PYTHONSAFEPATH"] else []));

    preWrapperShellCode = if builtins.isString bashBeforeWrapper
      then bashBeforeWrapper
      else builtins.concatStringsSep "\n" ([/*bash*/''
        NVIM_WRAPPER_PATH_NIX="$(${pkgs.coreutils}/bin/readlink -f "$0")"
        export NVIM_WRAPPER_PATH_NIX
      ''] ++ (pkgs.lib.unique (filterAndFlatten bashBeforeWrapper)));

    # add our propagated build dependencies
    baseNvimUnwrapped = if settings.neovim-unwrapped == null then pkgs.neovim-unwrapped else settings.neovim-unwrapped;
    myNeovimUnwrapped = if settings.nvimSRC != null || buildInputs != [] then baseNvimUnwrapped.overrideAttrs (prev: {
      src = if settings.nvimSRC != null then settings.nvimSRC else prev.src;
      propagatedBuildInputs = buildInputs ++ (prev.propagatedBuildInputs or []);
    }) else baseNvimUnwrapped;

  in
  # add our lsps and plugins and our config, and wrap it all up!
  # nothing goes past this file that hasnt been sorted
import ./wrapNeovim.nix {
  nixCats_passthru = nixCats_passthru // (let
    utils = (import ../utils).utils;
  in {
    keepLuaBuilder = utils.baseBuilder luaPath;
    nixCats_packageName = name;
    inherit categoryDefinitions packageDefinitions dependencyOverlays luaPath utils;
    nixosModule = utils.mkNixosModules {
      defaultPackageName = name;
      inherit dependencyOverlays luaPath
        categoryDefinitions packageDefinitions extra_pkg_config nixpkgs;
    };
    # and the same for home manager
    homeModule = utils.mkHomeModules {
      defaultPackageName = name;
      inherit dependencyOverlays luaPath
        categoryDefinitions packageDefinitions extra_pkg_config nixpkgs;
    };
  });
  inherit pkgs;
  neovim-unwrapped = myNeovimUnwrapped;
  inherit extraMakeWrapperArgs nixCats preWrapperShellCode customRC;
  inherit (settings) vimAlias viAlias withRuby withPerl extraName withNodeJs aliases gem_path;
  collate_grammars = true;
  pluginsOG.myVimPackage = {
    inherit start opt;
  };
    /* the function you would have passed to python.withPackages */
  # extraPythonPackages = combineCatsOfFuncs extraPythonPackages;
    /* the function you would have passed to python.withPackages */
  withPython3 = settings.withPython3;
  extraPython3Packages = combineCatsOfFuncs extraPython3Packages;
  extraPython3wrapperArgs = python3wrapperArgs;
    /* the function you would have passed to lua.withPackages */
  extraLuaPackages = combineCatsOfFuncs extraLuaPackages;
}
