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
  };
  packageDefinitions = {
    ${packagename} = { pkgs, ... }: {
      settings = {
      };
      categories = {
      };
    };
  };
in utils.baseBuilder luaPath {
    inherit (inputs) nixpkgs;
    inherit system dependencyOverlays
    extra_pkg_config nixCats_passthru;
  } categoryDefinitions packageDefinitions packagename
