# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
helpPath: path: pkgs:
categoryDefFunction:
packageDefinitons: name:
  # for a more extensive guide to this file
  # see :help nixCats.flake.nixperts.nvimBuilder
let
  inherit (
    {
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
      optionalLuaAdditions = "";
    } // (categoryDefFunction (packageDefinitons.${name}))
  )
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

    # package entire flake into the store
    LuaConfig = pkgs.stdenv.mkDerivation {
      name = builtins.baseNameOf path;
      builder = builtins.toFile "builder.sh" ''
        source $stdenv/setup
        mkdir -p $out
        cp -r ${path}/* $out/
      '';
    };

    # see :help nixCats
    nixCats = pkgs.stdenv.mkDerivation {
      name = "nixCats";
      builder = let
        categoriesPlus = categories // {
            inherit (settings) wrapRc;
            nixCats_packageName = name;
          };
        cats = builtins.toFile "nixCats.lua" ''
            vim.api.nvim_create_user_command('NixCats', 
            [[lua print(vim.inspect(require('nixCats')))]] , 
            { desc = 'So Cute!' })
            return ${(import ../utils).luaTablePrinter categoriesPlus}
          '';
      in builtins.toFile "builder.sh" ''
        source $stdenv/setup
        mkdir -p $out/lua
        mkdir -p $out/doc
        cp ${cats} $out/lua/nixCats.lua
        cp -r ${helpPath}/* $out/doc
      '';
    };

    # create our customRC to call it
    # This makes sure our config is loaded first and our after is loaded last
    # it also removes the regular config dir from the path.
    # the wrapper we are using might put it in the wrong place for our uses.
    # so we add in the config directory ourselves to prevent any issues.
    configDir = if settings.configDirName != null && settings.configDirName != ""
      then settings.configDirName else "nvim";
    customRC = ''
        let configdir = expand('~') . "/.config/${configDir}"
        execute "set runtimepath-=" . configdir
        execute "set runtimepath-=" . configdir . "/after"
      '' + (if settings.wrapRc then ''
        let runtimepath_list = split(&runtimepath, ',')
        call insert(runtimepath_list, "${LuaConfig}", 0)
        let &runtimepath = join(runtimepath_list, ',')

        set runtimepath+=${LuaConfig}/after

        lua package.path = package.path .. ';${LuaConfig}/init.lua'
        lua require('${builtins.baseNameOf LuaConfig}')
      '' else ''
        let runtimepath_list = split(&runtimepath, ',')
        call insert(runtimepath_list, configdir, 0)
        let &runtimepath = join(runtimepath_list, ',')

        execute "set runtimepath+=" . configdir . "/after"

        lua package.path = package.path .. ';' .. vim.api.nvim_get_var('configdir') .. '/init.lua'
        lua require('${configDir}')
      '') + ''
        lua << EOF
        ${optionalLuaAdditions}
        EOF
      '';
      # optionalLuaAdditions is not the suggested way to add lua to this flake
      # only for use when importing flake in a flake 
      # and need to add a bit of lua for an added plugin
      # you could add a new directory though idk thats your buisness.


    # this is what allows for dynamic packaging in flake.nix
    # It includes categories marked as true, then flattens to a single list
    filterAndFlatten = (import ../utils)
          .filterAndFlattenAttrsOfLists pkgs categories;

    # I didnt add stdenv.cc.cc.lib, so I would suggest not removing it.
    # It has cmake in it I think among other things?
    buildInputs = [ pkgs.stdenv.cc.cc.lib ] ++ filterAndFlatten propagatedBuildInputs;
    start = [ nixCats ] ++ filterAndFlatten startupPlugins;
    opt = filterAndFlatten optionalPlugins;

    # For wrapperArgs:
    # This one filters and flattens like above but for attrs of attrs 
    # and then maps name and value
    # into a list based on the function we provide it.
    # its like a flatmap function but with a built in filter for category.
    filterAndFlattenWrapAttrs = (import ../utils)
          .FilterAttrsOfAttrsFlatMapInner pkgs categories;
    # This one filters and flattens attrs of lists and then maps value
    # into a list of strings based on the function we provide it.
    # it the same as above but for a mapping function with 1 argument
    # because the inner is a list not a set.
    filterAndFlattenWrapLists = (import ../utils)
          .FilterAttrsOfListsFlatMapInner pkgs categories;

    # and then applied:

    FandF_envVarSet = filterAndFlattenWrapAttrs 
          (name: value: ''--set ${name} "${value}"'');

    FandF_passWrapperArgs = filterAndFlattenWrapLists (value: value);

    # add any dependencies/lsps/whatever we need available at runtime
    FandF_WrapRuntimeDeps = filterAndFlattenWrapLists (value:
      ''--prefix PATH : "${pkgs.lib.makeBinPath [ value ] }"''
    );

    # extraPythonPackages and the like require FUNCTIONS that return lists.
    # so we make a function that returns a function that returns lists.
    # this is used for the fields in the wrapper where the default value is (_: [])
    combineCatsOfFuncs = sect:
      (x: let
        appliedfunctions = builtins.map (value: (value) x ) (filterAndFlatten sect);
        combinedFuncRes = builtins.concatLists appliedfunctions;
        uniquifiedList = pkgs.lib.unique combinedFuncRes;
      in
      uniquifiedList);

    # cat our args
    extraMakeWrapperArgs = builtins.concatStringsSep " " (
      # this sets the name of the folder to look for nvim stuff in
      (if configDir != "nvim" then [ ''--set NVIM_APPNAME "${configDir}"'' ] else [])
      # and these are our other now sorted args
      ++ (FandF_WrapRuntimeDeps lspsAndRuntimeDeps)
      ++ (FandF_envVarSet environmentVariables)
      ++ (FandF_passWrapperArgs extraWrapperArgs)
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
