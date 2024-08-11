# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
{ luaPath
, categoryDefinitions
, packageDefinitions
, name
, nixpkgs
, system
, extra_pkg_config ? {}
, dependencyOverlays ? null
, nixCats_passthru ? {}
}:
let
  pkgs = with builtins; if isAttrs nixCats_passthru && isAttrs extra_pkg_config &&
      (isList dependencyOverlays || isAttrs dependencyOverlays || isNull dependencyOverlays)
  then import nixpkgs {
    inherit system;
    config = extra_pkg_config;
    overlays = if isList dependencyOverlays
      then dependencyOverlays
      else if isAttrs dependencyOverlays && hasAttr system dependencyOverlays
      then dependencyOverlays.${system}
      else [];
  } else throw error_message;
  error_message = ''
    The following arguments are accepted:

    # -------------------------------------------------------- #

    # the path to your ~/.config/nvim replacement within your nix config.
    luaPath: # <-- must be a store path

    { # set of items for building the pkgs that builds your neovim

      , nixpkgs # <-- required
      , system # <-- required

      # type: (attrsOf listOf overlays) or (listOf overlays) or null
      , dependencyOverlays ? null 

      # import nixpkgs { config = extra_pkg_config; inherit system; }
      , extra_pkg_config ? {} # type: attrs

      # any extra stuff for finalPackage.passthru
      , nixCats_passthru ? {} # type: attrs
    }:

    # type: function with args { pkgs, settings, categories, name, ... }:
    # returns: set of sets of categories
    # see :h nixCats.flake.outputs.categories
    categoryDefinitions: 

    # type: function with args { pkgs, ... }:
    # returns: { settings = {}; categories = {}; }
    packageDefinitions: 
    # see :h nixCats.flake.outputs.packageDefinitions
    # see :h nixCats.flake.outputs.settings

    # name of the package to built from packageDefinitions
    name: 

    # -------------------------------------------------------- #

    # Note:
    When using override, all values shown above will
    be top level attributes of prev, none will be nested.

    i.e. finalPackage.override (prev: { inherit (prev) dependencyOverlays; })
      NOT prev.pkgsargs.dependencyOverlays or something like that
  '';

  thisPackage = packageDefinitions.${name} { inherit pkgs; };
  categories = thisPackage.categories;
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
  } // thisPackage.settings;

  inherit ({
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
  } // (categoryDefinitions {
    inherit settings categories pkgs name;
  }))
  startupPlugins optionalPlugins lspsAndRuntimeDeps
  propagatedBuildInputs environmentVariables
  extraWrapperArgs extraPython3Packages
  extraLuaPackages optionalLuaAdditions
  extraPython3wrapperArgs sharedLibraries
  optionalLuaPreInit bashBeforeWrapper;

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
    nixCats = { ... }@allPluginDeps:
    pkgs.stdenv.mkDerivation (let
      isUnwrappedCfgPath = settings.wrapRc == false && settings.unwrappedCfgPath != null && builtins.isString settings.unwrappedCfgPath;
      isStdCfgPath = settings.wrapRc == false && ! isUnwrappedCfgPath;

      # command injection. The user can just straight up pass lua code
      # in categoryDefinitions so users have no reason to use this.
      # however, for our purposes, this is the cleanest and most 
      # performant way to replace the config location with a lua function value.
      nixCats_store_config_location = if isUnwrappedCfgPath
        then "${settings.unwrappedCfgPath}" else if isStdCfgPath then '']] .. vim.fn.stdpath("config") .. [['' else "${LuaConfig}";
      # I wish I named it nixCats_config_location but its used in the lazy wrapper so... too late for that.
      # I cant change the lazy wrapper in THEIR configs. I could have them pull the template again but I deemed that too annoying for them.

      categoriesPlus = categories // {
        nixCats_wrapRc = settings.wrapRc;
        nixCats_packageName = name;
        inherit nixCats_store_config_location;
      };
      settingsPlus = settings // {
        nixCats_packageName = name;
        inherit nixCats_store_config_location;
      };
      # using writeText instead of builtins.toFile allows us to pass derivation names and paths.
      cats = pkgs.writeText "cats.lua" ''return ${(import ./ncTools.nix).luaTablePrinter categoriesPlus}'';
      settingsTable = pkgs.writeText "settings.lua" ''return ${(import ./ncTools.nix).luaTablePrinter settingsPlus}'';
      depsTable = pkgs.writeText "pawsible.lua" ''return ${(import ./ncTools.nix).luaTablePrinter allPluginDeps}'';
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
        cp -r ${../nixCatsHelp}/* $out/doc/
      '';
    });

    # doing it as 2 parts, this before any nix included plugin config,
    # and then running init.lua after makes nixCats command and
    # configdir variable available even for lua written in nix
    runB4Config = /* lua */''
      vim.g.configdir = vim.fn.stdpath('config')
      vim.opt.packpath:remove(vim.g.configdir)
      vim.opt.runtimepath:remove(vim.g.configdir)
      vim.opt.runtimepath:remove(vim.g.configdir .. "/after")
      vim.g.configdir = require('nixCats').get([[nixCats_store_config_location]])
      require('nixCats').addGlobals()
      vim.opt.packpath:prepend(vim.g.configdir)
      vim.opt.runtimepath:prepend(vim.g.configdir)
      vim.opt.runtimepath:append(vim.g.configdir .. "/after")
    '';

    customRC = let
      optLuaPre = if builtins.isString optionalLuaPreInit
          then optionalLuaPreInit
          else builtins.concatStringsSep "\n"
          (pkgs.lib.unique (filterAndFlatten optionalLuaPreInit));
      optLuaAdditions = if builtins.isString optionalLuaAdditions
          then optionalLuaAdditions
          else builtins.concatStringsSep "\n"
          (pkgs.lib.unique (filterAndFlatten optionalLuaAdditions));
    in/* lua */''
      ${optLuaPre}
      vim.g.configdir = require('nixCats').get([[nixCats_store_config_location]])
      if vim.fn.filereadable(vim.g.configdir .. "/init.vim") == 1 then
        vim.cmd.source(vim.g.configdir .. "/init.vim")
      end
      if vim.fn.filereadable(vim.g.configdir .. "/init.lua") == 1 then
        dofile(vim.g.configdir .. "/init.lua")
      end
      ${optLuaAdditions}
    '';

    # this is what allows for dynamic packaging in flake.nix
    # It includes categories marked as true, then flattens to a single list
    filterAndFlatten = (import ./ncTools.nix).filterAndFlatten categories;

    buildInputs = [ pkgs.stdenv.cc.cc.lib ] ++ pkgs.lib.unique (filterAndFlatten propagatedBuildInputs);
    start = pkgs.lib.unique (filterAndFlatten startupPlugins);
    opt = pkgs.lib.unique (filterAndFlatten optionalPlugins);

    # For wrapperArgs:
    # This one filters and flattens like above but for attrs of attrs 
    # and then maps name and value
    # into a list based on the function we provide it.
    # its like a flatmap function but with a built in filter for category.
    filterAndFlattenMapInnerAttrs = (import ./ncTools.nix)
          .filterAndFlattenMapInnerAttrs categories;
    # This one filters and flattens attrs of lists and then maps value
    # into a list of strings based on the function we provide it.
    # it the same as above but for a mapping function with 1 argument
    # because the inner is a list not a set.
    filterAndFlattenMapInner = (import ./ncTools.nix)
          .filterAndFlattenMapInner categories;

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
    myNeovimUnwrapped = baseNvimUnwrapped.overrideAttrs (prev: {
      src = if settings.nvimSRC != null then settings.nvimSRC else prev.src;
      propagatedBuildInputs = buildInputs;
    });

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
        categoryDefinitions packageDefinitions nixpkgs;
    };
    # and the same for home manager
    homeModule = utils.mkHomeModules {
      defaultPackageName = name;
      inherit dependencyOverlays luaPath
        categoryDefinitions packageDefinitions nixpkgs;
    };
  });
  inherit pkgs nixpkgs;
  neovim-unwrapped = myNeovimUnwrapped;
  inherit extraMakeWrapperArgs nixCats runB4Config preWrapperShellCode customRC;
  inherit (settings) vimAlias viAlias withRuby withPerl extraName withNodeJs aliases gem_path;
  pluginsOG.myVimPackage = {
    start = start;
    inherit opt;
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
