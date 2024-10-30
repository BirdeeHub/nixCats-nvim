{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, ... }@inputs: let
    utils = import ../.;
    forAllSys = utils.eachSystem nixpkgs.lib.platforms.all;
    mkTestVim = system: let
      luaPath = ./.;
      dependencyOverlays = [
      ];
      categoryDefinitions = { pkgs, settings, categories, name, ... }@packageDef: {
      };
      packageDefinitions = {
        testvim = { pkgs, ... }: {
          settings = {
          };
          categories = {
            killAfter = true;
          };
        };
      };
    in utils.baseBuilder luaPath {
        inherit nixpkgs system dependencyOverlays;
        extra_pkg_config = {
          allowUnfree = true;
        };
        nixCats_passthru = {};
      } categoryDefinitions packageDefinitions "testvim";
  in forAllSys (system: let
    pkgs = import nixpkgs { inherit system; };
    testvim = mkTestVim system;
    hometests = pkgs.callPackage ./home { inherit testvim inputs; };
    drvtests = pkgs.callPackage ./drv { inherit testvim inputs; };
  in
  {
    checks = {
      inherit hometests;
      drv = drvtests;
    };
  });
}
