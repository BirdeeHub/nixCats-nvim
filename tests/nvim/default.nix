{ utils, system, inputs, packagename, ... }: let
  luaPath = ./.;
  extra_pkg_config = {
    allowUnfree = true;
  };
  nixCats_passthru = {};
  dependencyOverlays = [
  ];
  categoryDefinitions = { pkgs, settings, categories, name, ... }@packageDef: {
  };
  packageDefinitions = {
    ${packagename} = { pkgs, ... }: {
      settings = {
      };
      categories = {
        killAfter = true;
      };
    };
  };
in
utils.baseBuilder luaPath {
  inherit system dependencyOverlays extra_pkg_config nixCats_passthru;
  inherit (inputs) nixpkgs;
} categoryDefinitions packageDefinitions packagename
