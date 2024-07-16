# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
luaPath:
{
  pkgs ? null # <-- either this with everything included,
  , nixpkgs ? null # <-- or this one
  , extra_pkg_config ? {}
  , system ? null # <-- and this one
  , dependencyOverlays ? null # <-- and this one
  , nixCats_passthru ? {}
  , ...
}:
categoryDefFunction:
packageDefinitions: name:
let
  fpkgs = if pkgs == null && !(nixpkgs == null || system == null)
  then import nixpkgs ({
    inherit system;
    overlays = if builtins.isList dependencyOverlays
      then dependencyOverlays
      else if builtins.isAttrs dependencyOverlays && builtins.hasAttr system dependencyOverlays
      then dependencyOverlays.${system}
      else [];
  } // { config = extra_pkg_config; })
  else if pkgs != null then pkgs
  else builtins.throw ''
    Arguments accepted:

    luaPath:
    {
      pkgs ? null                 # <-- either pkgs with everything included
      , nixpkgs ? null            # <-- or include nixpkgs,
      , system ? null             # <-- and system
      , dependencyOverlays ? null # <-- and the overlays
      , extra_pkg_config ? {}     # <-- extra config such as allowUnfree
      , nixCats_passthru ? {}     # <-- extra things to add to passthru attribute of derivation
      , ...
    }:
    categoryDefFunction:
    packageDefinitions:
    packageName:

    # Note:
    You must provide nixpkgs and system along with any dependencyOverlays,
    or a pkgs attribute to the nixCats builder function
    in the set recieved as the second argument

    dependencyOverlays can recieve either a list of overlays, or a set of dependencyOverlays.''${system}
  '';

  thisPackage = packageDefinitions.${name} { pkgs = fpkgs; };
  categories = thisPackage.categories;
  settings = {
    wrapRc = true;
    viAlias = false;
    vimAlias = false;
    withNodeJs = false;
    withRuby = true;
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
  } // (categoryDefFunction {
    pkgs = fpkgs;
    inherit settings categories name;
  }))
  startupPlugins optionalPlugins lspsAndRuntimeDeps
  propagatedBuildInputs environmentVariables
  extraWrapperArgs extraPython3Packages
  extraLuaPackages optionalLuaAdditions
  extraPython3wrapperArgs sharedLibraries;

in
  let
    # copy entire flake to store directory
    LuaConfig = fpkgs.stdenv.mkDerivation {
      name = "nixCats-special-rtp-entry-LuaConfig";
      builder = fpkgs.writeText "builder.sh" /* bash */ ''
        source $stdenv/setup
        mkdir -p $out
        cp -r ${luaPath}/* $out/
      '';
    };

    # see :help nixCats
    # this function gets passed all the way into the wrapper so that we can also add
    # other dependencies that get resolved later in the process such as treesitter grammars.
    nixCats = { ... }@allPluginDeps:
    fpkgs.stdenv.mkDerivation (let
      categoriesPlus = categories // {
        nixCats_wrapRc = settings.wrapRc;
        nixCats_packageName = name;
        nixCats_store_config_location = "${LuaConfig}";
      };
      settingsPlus = settings // {
        nixCats_packageName = name;
        nixCats_store_config_location = "${LuaConfig}";
      };
      # using writeText instead of builtins.toFile allows us to pass derivation names and paths.
      cats = fpkgs.writeText "cats.lua" ''return ${(import ./ncTools.nix).luaTablePrinter categoriesPlus}'';
      settingsTable = fpkgs.writeText "settings.lua" ''return ${(import ./ncTools.nix).luaTablePrinter settingsPlus}'';
      depsTable = fpkgs.writeText "pawsible.lua" ''return ${(import ./ncTools.nix).luaTablePrinter allPluginDeps}'';
    in {
      name = "nixCats";
      builder = fpkgs.writeText "builder.sh" /* bash */ ''
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

    setconfigdir = if settings.wrapRc then ''
      vim.g.configdir = [[${LuaConfig}]]
    '' else if settings.unwrappedCfgPath != null then ''
      vim.g.configdir = [[${settings.unwrappedCfgPath}]]
    '' else /*lua*/''
      vim.g.configdir = vim.fn.stdpath('config')
    '';

    # doing it as 2 parts, this before any nix included plugin config,
    # and then running init.lua after makes nixCats command and
    # configdir variable available even for lua written in nix
    runB4Config = (/* lua */''
      vim.g.configdir = vim.fn.stdpath('config')
      vim.opt.packpath:remove(vim.g.configdir)
      vim.opt.runtimepath:remove(vim.g.configdir)
      vim.opt.runtimepath:remove(vim.g.configdir .. "/after")
    '') + setconfigdir + /* lua */ ''
      require('nixCats').addGlobals()
      require('nixCats.saveTheCats')
      vim.opt.packpath:prepend(vim.g.configdir)
      vim.opt.runtimepath:prepend(vim.g.configdir)
      vim.opt.runtimepath:append(vim.g.configdir .. "/after")
    '';

    customRC = setconfigdir + /* lua */''
      if vim.fn.filereadable(vim.g.configdir .. "/init.vim") == 1 then
        vim.cmd.source(vim.g.configdir .. "/init.vim")
      end
      if vim.fn.filereadable(vim.g.configdir .. "/init.lua") == 1 then
        dofile(vim.g.configdir .. "/init.lua")
      end
    '';

    # this is what allows for dynamic packaging in flake.nix
    # It includes categories marked as true, then flattens to a single list
    filterAndFlatten = (import ./ncTools.nix).filterAndFlatten categories;

    buildInputs = [ fpkgs.stdenv.cc.cc.lib ] ++ fpkgs.lib.unique (filterAndFlatten propagatedBuildInputs);
    start = fpkgs.lib.unique (filterAndFlatten startupPlugins);
    opt = fpkgs.lib.unique (filterAndFlatten optionalPlugins);

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
        uniquifiedList = fpkgs.lib.unique combinedFuncRes;
      in
      uniquifiedList);

    optLuaAdditions = if builtins.isString optionalLuaAdditions
        then optionalLuaAdditions
        else builtins.concatStringsSep "\n"
        (fpkgs.lib.unique (filterAndFlatten optionalLuaAdditions));

    # cat our args
    extraMakeWrapperArgs = let 
      linkables = fpkgs.lib.unique (filterAndFlatten sharedLibraries);
      pathEnv = fpkgs.lib.unique (filterAndFlatten lspsAndRuntimeDeps);
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
            then [ ''--${preORpostPATH} PATH : "${fpkgs.lib.makeBinPath pathEnv }"'' ]
          else [])
      ++ (if linkables != []
            then [ ''--${preORpostLD} LD_LIBRARY_PATH : "${fpkgs.lib.makeLibraryPath linkables }"'' ]
          else [])
      ++ (fpkgs.lib.unique (FandF_envVarSet environmentVariables))
      ++ (fpkgs.lib.unique (filterAndFlatten extraWrapperArgs))
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
    );

    python3wrapperArgs = fpkgs.lib.unique ((filterAndFlatten extraPython3wrapperArgs) ++ (if settings.disablePythonSafePath then ["--unset PYTHONSAFEPATH"] else []));

    # add our propagated build dependencies
    baseNvimUnwrapped = if settings.neovim-unwrapped == null then fpkgs.neovim-unwrapped else settings.neovim-unwrapped;
    myNeovimUnwrapped = baseNvimUnwrapped.overrideAttrs (prev: {
      src = if settings.nvimSRC != null then settings.nvimSRC else prev.src;
      propagatedBuildInputs = buildInputs;
    });

  in
  # add our lsps and plugins and our config, and wrap it all up!
  # nothing goes past this file that hasnt been sorted
import ./wrapNeovim.nix fpkgs myNeovimUnwrapped {
  nixCats_passthru = nixCats_passthru // {
    keepLuaBuilder = import ./. luaPath;
    nixCats_packageName = name;
    utils = (import ../utils).utils;
    categoryDefinitions = categoryDefFunction;
    packageDefinitions = packageDefinitions;
    inherit dependencyOverlays optLuaAdditions;
  };

  inherit extraMakeWrapperArgs nixCats runB4Config;
  inherit (settings) vimAlias viAlias withRuby withPerl extraName withNodeJs aliases;
  configure = {
    inherit customRC;
    packages.myVimPackage = {
      start = start;
      inherit opt;
    };
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
