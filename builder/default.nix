# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
{
  nclib
  , utils
}:
{ luaPath
, categoryDefinitions
, packageDefinitions
, name
, nixpkgs
, system ? (nixpkgs.system or builtins.system or import ./builder_error.nix)
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
  in if isAttrs extra_pkg_config && isAttrs nixCats_passthru
    && isFunction categoryDefinitions && isAttrs packageDefinitions && isString name
    && (isPath luaPath || (isString luaPath && hasContext luaPath) || luaPath.outPath or null != null)
  then import (nixpkgs.path or nixpkgs.outPath or nixpkgs)
    { inherit system config overlays; }
  else import ./builder_error.nix;

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

  # for the env vars section
  FandF_envVarSet = set: pkgs.lib.pipe set [
    (filterAndFlattenMapInnerAttrs (name: value: pkgs.lib.escapeShellArgs [ "--set" name value ]))
    pkgs.lib.unique
  ];

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
    optLuaPre = let
      lua = if builtins.isString optionalLuaPreInit
        then optionalLuaPreInit
        else builtins.concatStringsSep "\n"
        (filterFlattenUnique optionalLuaPreInit);
    in if lua != "" then "dofile([[${pkgs.writeText "optLuaPre.lua" lua}]])" else "";
    optLuaAdditions = let
      lua = if builtins.isString optionalLuaAdditions
        then optionalLuaAdditions
        else builtins.concatStringsSep "\n"
        (filterFlattenUnique optionalLuaAdditions);
    in if lua != "" then "dofile([[${pkgs.writeText "optLuaAdditions.lua" lua}]])" else "";
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
    preORpostPATH = if settings.suffix-path then "suffix" else "prefix";
    pathEnv = filterFlattenUnique lspsAndRuntimeDeps;
    preORpostLD = if settings.suffix-LD then "suffix" else "prefix";
    linkables = filterFlattenUnique sharedLibraries;
    envVars = FandF_envVarSet environmentVariables;
    userWrapperArgs = filterFlattenUnique extraWrapperArgs;
  in pkgs.lib.escapeShellArgs (pkgs.lib.optionals 
      (settings.configDirName != null && settings.configDirName != "" || settings.configDirName != "nvim") [
      "--set" "NVIM_APPNAME" settings.configDirName # this sets the name of the folder to look for nvim stuff in
    ] ++ (pkgs.lib.optionals (pathEnv != []) [
      "--${preORpostPATH}" "PATH" ":" (pkgs.lib.makeBinPath pathEnv)
    ]) ++ (pkgs.lib.optionals (linkables != []) [
      "--${preORpostLD}" "LD_LIBRARY_PATH" ":" (pkgs.lib.makeLibraryPath linkables)
    ])) + " " + (builtins.concatStringsSep " " (envVars ++ userWrapperArgs));

  python3wrapperArgs = pkgs.lib.unique
    (pkgs.lib.optionals settings.disablePythonPath ["--unset PYTHONPATH"]
    ++ (pkgs.lib.optionals settings.disablePythonSafePath ["--unset PYTHONSAFEPATH"])
    ++ (filterAndFlatten extraPython3wrapperArgs));

  preWrapperShellCode = if builtins.isString bashBeforeWrapper
    then bashBeforeWrapper
    else builtins.concatStringsSep "\n" ([/*bash*/''
      NVIM_WRAPPER_PATH_NIX="$(${pkgs.coreutils}/bin/readlink -f "$0")"
      export NVIM_WRAPPER_PATH_NIX
    ''] ++ (filterFlattenUnique bashBeforeWrapper));

  # add our propagated build dependencies
  baseNvimUnwrapped = if settings.neovim-unwrapped == null then pkgs.neovim-unwrapped else settings.neovim-unwrapped;
  myNeovimUnwrapped = if settings.nvimSRC != null || buildInputs != [] then baseNvimUnwrapped.overrideAttrs (prev: {
    src = if settings.nvimSRC != null then settings.nvimSRC else prev.src;
    propagatedBuildInputs = buildInputs ++ (prev.propagatedBuildInputs or []);
  }) else baseNvimUnwrapped;

  nc_passthru = nixCats_passthru // {
    keepLuaBuilder = utils.baseBuilder luaPath;
    nixCats_packageName = name;
    inherit categoryDefinitions packageDefinitions dependencyOverlays luaPath utils;
    inherit (settings) moduleNamespace;
    nixosModule = utils.mkNixosModules {
      defaultPackageName = name;
      inherit dependencyOverlays luaPath
        categoryDefinitions packageDefinitions extra_pkg_config nixpkgs;
      inherit (settings) moduleNamespace;
    };
    # and the same for home manager
    homeModule = utils.mkHomeModules {
      defaultPackageName = name;
      inherit dependencyOverlays luaPath
        categoryDefinitions packageDefinitions extra_pkg_config nixpkgs;
      inherit (settings) moduleNamespace;
    };
  };
in
# NOTE: nothing goes past this file that hasnt been sorted
import ./wrapNeovim.nix {
  inherit pkgs;
  neovim-unwrapped = myNeovimUnwrapped;
  nixCats_passthru = nc_passthru;
  inherit extraMakeWrapperArgs nixCats ncTools preWrapperShellCode customRC;
  inherit (settings) vimAlias viAlias withRuby withPerl extraName withNodeJs aliases gem_path collate_grammars autowrapRuntimeDeps;
  inherit (normalized) start opt;
    /* the function you would have passed to python.withPackages */
  # extraPythonPackages = combineCatsOfFuncs extraPythonPackages;
    /* the function you would have passed to python.withPackages */
  withPython3 = settings.withPython3;
  extraPython3Packages = combineCatsOfFuncs extraPython3Packages;
  extraPython3wrapperArgs = python3wrapperArgs;
    /* the function you would have passed to lua.withPackages */
  extraLuaPackages = combineCatsOfFuncs extraLuaPackages;
}
