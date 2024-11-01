{ system, inputs, utils, packagename, ... }: let
  luaPath = ./.;
  nixCats_passthru = {};
  extra_pkg_config = {
    allowUnfree = true;
  };
  dependencyOverlays = [
    (utils.standardPluginOverlay inputs)
  ];
  categoryDefinitions = { pkgs, settings, categories, name, ... }@packageDef: {
    startupPlugins = {
      nixCats_test_lib_deps = with pkgs.vimPlugins; [
        lze
      ];
    };
    extraLuaPackages = {
      nixCats_test_lib_deps = (lp: with lp; [
        ansicolors
        luassert
      ]);
    };
  };
  packageDefinitions = {
    ${packagename} = { pkgs, ... }: {
      settings = {
      };
      categories = {
        nixCats_test_lib_deps = true;
        killAfter = true;
      };
    };
  };
in utils.baseBuilder luaPath {
    inherit (inputs) nixpkgs;
    inherit system dependencyOverlays
    extra_pkg_config nixCats_passthru;
  } categoryDefinitions packageDefinitions packagename
