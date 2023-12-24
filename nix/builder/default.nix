# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
path: pkgs:
categoryDefFunction:
packageDefinitons: name:
  # for a more extensive guide to this file
  # see :help nixCats.flake.nixperts.nvimBuilder
let
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
  } // (categoryDefFunction (packageDefinitons.${name}));
  inherit (catDefs)
  startupPlugins optionalPlugins 
  lspsAndRuntimeDeps propagatedBuildInputs
  environmentVariables extraWrapperArgs 
  extraPythonPackages extraPython3Packages
  extraLuaPackages optionalLuaAdditions;

  settings = {
    wrapRc = true;
    viAlias = false;
    vimAlias = false;
    withNodeJs = false;
    withRuby = true;
    extraName = "";
    withPython3 = true;
    configDirName = "nvim";
    nvimSRC = null;
  } // packageDefinitons.${name}.settings;

  categories = packageDefinitons.${name}.categories;

in
  let
    # copy entire flake to store directory
    LuaConfig = pkgs.stdenv.mkDerivation {
      name = builtins.baseNameOf path;
      builder = builtins.toFile "builder.sh" ''
        source $stdenv/setup
        mkdir -p $out
        cp -r ${path}/* $out/
      '';
    };

    # see :help nixCats
    nixCats = {
      plugin = pkgs.stdenv.mkDerivation (let
        categoriesPlus = categories // {
            inherit (settings) wrapRc;
            nixCats_packageName = name;
          };
        init = builtins.toFile "init.lua" (builtins.readFile ./nixCats.lua);
        plugin = builtins.toFile "globalCats.lua" (builtins.readFile ./globalCats.lua);
        # we import as a string because you cannot pass derivation paths when using toFile
        cats = ''return ${(import ../utils).luaTablePrinter categoriesPlus}'';
        # nix attr names can have ' characters....
        # Yes they show up unaltered now in lua....................
        cleanCats = builtins.replaceStrings [ "'" ] [ "\'\"\'\"\'" ] cats;
      in {
        name = "nixCats";
        src = ../nixCatsHelp;
        phases = [ "buildPhase" "installPhase" ];
        buildPhase = ''
          source $stdenv/setup
          mkdir -p $out/lua/nixCats
          mkdir -p $out/doc
          mkdir -p $out/plugin
          cp ${init} $out/lua/nixCats/init.lua
          cp ${plugin} $out/plugin/globalCats.lua
          echo '${cleanCats}' > $out/lua/nixCats/cats.lua
        '';
        installPhase = ''
          cp -r $src/* $out/doc/
        '';
      });
      # doing it this way makes nixCats command and
      # configdir variable available even with new plugin scheme
      config.vim = ''
        packadd nixCats
        let configdir = stdpath('config')
        execute "set runtimepath-=" . configdir
        execute "set runtimepath-=" . configdir . "/after"
      '' + (if settings.wrapRc then ''
        let configdir = "${LuaConfig}"
      '' else "") + ''
        let runtimepath_list = split(&runtimepath, ',')
        call insert(runtimepath_list, configdir, 0)
        let &runtimepath = join(runtimepath_list, ',')
        execute "set runtimepath+=" . configdir . "/after"
      '';
    };

    customRC = let
      LuaAdditions = if builtins.isString optionalLuaAdditions
          then optionalLuaAdditions
          else builtins.concatStringsSep "\n"
          (pkgs.lib.unique (filterAndFlatten optionalLuaAdditions));
    in # just in case someone overwrites it.
    (if settings.wrapRc then ''
      let configdir = "${LuaConfig}"
    '' else ''
      let configdir = stdpath('config')
    '') + ''
      execute "source " . configdir . "/init.lua"

      lua << EOF
      ${LuaAdditions}
      EOF
    '';

    # this is what allows for dynamic packaging in flake.nix
    # It includes categories marked as true, then flattens to a single list
    filterAndFlatten = (import ../utils)
          .filterAndFlatten categories;

    buildInputs = [ pkgs.stdenv.cc.cc.lib ] ++ pkgs.lib.unique (filterAndFlatten propagatedBuildInputs);
    start = [ nixCats ] ++ pkgs.lib.unique (filterAndFlatten startupPlugins);
    opt = pkgs.lib.unique (filterAndFlatten optionalPlugins);

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
      ''--prefix PATH : "${pkgs.lib.makeBinPath [ value ] }"''
    );

    # extraPythonPackages and the like require FUNCTIONS that return lists.
    # so we make a function that returns a function that returns lists.
    # this is used for the fields in the wrapper where the default value is (_: [])
    combineCatsOfFuncs = section:
      (x: let
        appliedfunctions = filterAndFlattenMapInner (value: (value) x ) section;
        combinedFuncRes = builtins.concatLists appliedfunctions;
        uniquifiedList = pkgs.lib.unique combinedFuncRes;
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
      ++ (pkgs.lib.unique (FandF_WrapRuntimeDeps lspsAndRuntimeDeps))
      ++ (pkgs.lib.unique (FandF_envVarSet environmentVariables))
      ++ (pkgs.lib.unique (FandF_passWrapperArgs extraWrapperArgs))
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
    );

    # add our propagated build dependencies
    myNeovimUnwrapped = pkgs.neovim-unwrapped.overrideAttrs (prev: {
      src = if settings.nvimSRC != null then settings.nvimSRC else prev.src;
      propagatedBuildInputs = buildInputs;
    });

  in
  # add our lsps and plugins and our config, and wrap it all up!
(import ./wrapNeovim.nix).wrapNeovim pkgs myNeovimUnwrapped {
  inherit extraMakeWrapperArgs;
  inherit (settings) vimAlias viAlias withRuby extraName withNodeJs;
  configure = {
    inherit customRC;
    packages.myVimPackage = {
      inherit start opt;
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
