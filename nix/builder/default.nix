# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
path:
{
  pkgs ? null
  , nixpkgs ? null
  , extra_pkg_config ? {}
  , system ? null
  , dependencyOverlays
  , nixCats_passthru ? {}
  , ...
}@attrs:
categoryDefFunction:
packageDefinitons: name:
  # for a more extensive guide to this file
  # see :help nixCats.flake.nixperts.nvimBuilder
let
  fpkgs = if pkgs == null && !(nixpkgs == null || system == null)
  then import nixpkgs ({
    inherit system;
    overlays = if builtins.isList dependencyOverlays
      then dependencyOverlays
      else if builtins.isAttrs dependencyOverlays
      then dependencyOverlays.${system}
      else [];
  } // { config = extra_pkg_config; })
  else pkgs;
  catDefs = {
    startupPlugins = {};
    optionalPlugins = {};
    lspsAndRuntimeDeps = {};
    propagatedBuildInputs = {};
    environmentVariables = {};
    extraWrapperArgs = {};
  # the source says:
    /* the function you would have passed to python.withPackages */
  # So you put in a set of categories of lists of them.
    extraPythonPackages = {};
    extraPython3Packages = {};
  # same thing except for lua.withPackages
    extraLuaPackages = {};
  # only for use when importing flake in a flake 
  # and need to only add a bit of lua for an added plugin
    optionalLuaAdditions = {};
  } // (categoryDefFunction ({ inherit settings categories name; pkgs = fpkgs; }));
  inherit (catDefs)
  startupPlugins optionalPlugins 
  lspsAndRuntimeDeps propagatedBuildInputs
  environmentVariables extraWrapperArgs 
  extraPythonPackages extraPython3Packages
  extraLuaPackages optionalLuaAdditions;

  thisPackage = packageDefinitons.${name} { pkgs = fpkgs; };
  settings = {
    wrapRc = true;
    viAlias = false;
    vimAlias = false;
    withNodeJs = false;
    withRuby = true;
    rubyEnv = null;
    withPerl = false;
    extraName = "";
    withPython3 = true;
    configDirName = "nvim";
    aliases = null;
    nvimSRC = null;
  } // thisPackage.settings;

  categories = thisPackage.categories;

in
  let
    # copy entire flake to store directory
    LuaConfig = fpkgs.stdenv.mkDerivation {
      name = "nixCats-special-rtp-entry-LuaConfig";
      builder = builtins.toFile "builder.sh" /* bash */ ''
        source $stdenv/setup
        mkdir -p $out
        cp -r ${path}/* $out/
      '';
    };

    # see :help nixCats
    # this function gets passed all the way into the wrapper so that we can also add
    # other dependencies that get resolved later in the process such as treesitter grammars.
    nixCats = { ... }@allDeps:
    fpkgs.stdenv.mkDerivation (let
      categoriesPlus = categories // {
          nixCats_wrapRc = settings.wrapRc;
          nixCats_packageName = name;
          nixCats_store_config_location = "${LuaConfig}";
        };
      init = fpkgs.writeText "init.lua" (builtins.readFile ./nixCats.lua);
      # using writeText instead of builtins.toFile allows us to pass derivation names and paths.
      cats = fpkgs.writeText "cats.lua" ''return ${(import ../utils).luaTablePrinter categoriesPlus}'';
      depsTable = fpkgs.writeText "included.lua" ''return ${(import ../utils).luaTablePrinter allDeps}'';
    in {
      name = "nixCats";
      src = ../nixCatsHelp;
      phases = [ "buildPhase" "installPhase" ];
      buildPhase = ''
        source $stdenv/setup
        mkdir -p $out/lua/nixCats
        mkdir -p $out/doc
        cp ${init} $out/lua/nixCats/init.lua
        cp ${cats} $out/lua/nixCats/cats.lua
        cp ${depsTable} $out/lua/nixCats/included.lua
      '';
      installPhase = ''
        cp -r $src/* $out/doc/
      '';
    });
    # doing it this way makes nixCats command and
    # configdir variable available even with new plugin scheme
    # as well as any local pack dir
    runB4Config = (/* vim */ ''
      let configdir = stdpath('config')
      execute "set runtimepath-=" . configdir
      execute "set runtimepath-=" . configdir . "/after"
    '') + (if settings.wrapRc then /* vim */''
      let configdir = "${LuaConfig}"
    '' else "") + /* vim */ ''
      lua require('nixCats').addGlobals()
      lua require('nixCats.saveTheCats')
      let runtimepath_list = split(&runtimepath, ',')
      call insert(runtimepath_list, configdir, 0)
      let &runtimepath = join(runtimepath_list, ',')
      execute "set runtimepath+=" . configdir . "/after"
    '';

    customRC = let
      LuaAdditions = if builtins.isString optionalLuaAdditions
          then optionalLuaAdditions
          else builtins.concatStringsSep "\n"
          (fpkgs.lib.unique (filterAndFlatten optionalLuaAdditions));
    in # just in case someone overwrites it.
    (if settings.wrapRc then /* vim */ ''
      let configdir = "${LuaConfig}"
    '' else /* vim */ ''
      let configdir = stdpath('config')
    '') + /* vim */ ''
      execute "source " . configdir . "/init.lua"

      lua << EOF
      ${LuaAdditions}
      EOF
    '';

    # this is what allows for dynamic packaging in flake.nix
    # It includes categories marked as true, then flattens to a single list
    filterAndFlatten = (import ../utils)
          .filterAndFlatten categories;

    buildInputs = [ fpkgs.stdenv.cc.cc.lib ] ++ fpkgs.lib.unique (filterAndFlatten propagatedBuildInputs);
    start = fpkgs.lib.unique (filterAndFlatten startupPlugins);
    opt = fpkgs.lib.unique (filterAndFlatten optionalPlugins);

    # For wrapperArgs:
    # This one filters and flattens like above but for attrs of attrs 
    # and then maps name and value
    # into a list based on the function we provide it.
    # its like a flatmap function but with a built in filter for category.
    filterAndFlattenMapInnerAttrs = (import ../utils)
          .filterAndFlattenMapInnerAttrs categories;
    # This one filters and flattens attrs of lists and then maps value
    # into a list of strings based on the function we provide it.
    # it the same as above but for a mapping function with 1 argument
    # because the inner is a list not a set.
    filterAndFlattenMapInner = (import ../utils)
          .filterAndFlattenMapInner categories;

    # and then applied to give us a 1 argument function:

    FandF_envVarSet = filterAndFlattenMapInnerAttrs 
          (name: value: ''--set ${name} "${value}"'');

    FandF_passWrapperArgs = filterAndFlattenMapInner (value: value);

    # add any dependencies/lsps/whatever we need available at runtime
    FandF_WrapRuntimeDeps = filterAndFlattenMapInner (value:
      ''--prefix PATH : "${fpkgs.lib.makeBinPath [ value ] }"''
    );

    # extraPythonPackages and the like require FUNCTIONS that return lists.
    # so we make a function that returns a function that returns lists.
    # this is used for the fields in the wrapper where the default value is (_: [])
    combineCatsOfFuncs = section:
      (x: let
        appliedfunctions = filterAndFlattenMapInner (value: (value) x ) section;
        combinedFuncRes = builtins.concatLists appliedfunctions;
        uniquifiedList = fpkgs.lib.unique combinedFuncRes;
      in
      uniquifiedList);

    # cat our args
    extraMakeWrapperArgs = builtins.concatStringsSep " " (
      # this sets the name of the folder to look for nvim stuff in
      (if settings.configDirName != null
        && settings.configDirName != ""
        || settings.configDirName != "nvim"
        then [ ''--set NVIM_APPNAME "${settings.configDirName}"'' ] else [])
      # and these are our other now sorted args
      ++ (fpkgs.lib.unique (FandF_WrapRuntimeDeps lspsAndRuntimeDeps))
      ++ (fpkgs.lib.unique (FandF_envVarSet environmentVariables))
      ++ (fpkgs.lib.unique (FandF_passWrapperArgs extraWrapperArgs))
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
    );

    # add our propagated build dependencies
    myNeovimUnwrapped = fpkgs.neovim-unwrapped.overrideAttrs (prev: {
      src = if settings.nvimSRC != null then settings.nvimSRC else prev.src;
      propagatedBuildInputs = buildInputs;
    });

  in
  # add our lsps and plugins and our config, and wrap it all up!
(import ./wrapNeovim.nix).wrapNeovim fpkgs myNeovimUnwrapped {
  nixCats_passthru = nixCats_passthru // {
    keepLuaBuilder = (import ../utils).utils.baseBuilder path;
    nixCats_packageName = name;
    utils = (import ../utils).utils;
    categoryDefinitions = categoryDefFunction;
    inherit dependencyOverlays packageDefinitons;
  };

  inherit extraMakeWrapperArgs nixCats runB4Config;
  inherit (settings) vimAlias viAlias withRuby withPerl extraName withNodeJs rubyEnv aliases;
  configure = {
    inherit customRC;
    packages.myVimPackage = {
      start = start;
      inherit opt;
    };
  };
    /* the function you would have passed to python.withPackages */
  extraPythonPackages = combineCatsOfFuncs extraPythonPackages;
    /* the function you would have passed to python.withPackages */
  withPython3 = settings.withPython3;
  extraPython3Packages = combineCatsOfFuncs extraPython3Packages;
    /* the function you would have passed to lua.withPackages */
  extraLuaPackages = combineCatsOfFuncs extraLuaPackages;
}
