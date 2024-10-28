{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };
  outputs = { self, nixpkgs, ... }@inputs: let
    utils = import ../.;
    forAllSys = utils.eachSystem nixpkgs.lib.platforms.all;
    mkTestVim = system: import ./nvim {
      inherit system utils inputs;
      packagename = "testvim";
    };
  in forAllSys (system: let
    pkgs = import nixpkgs { inherit system; };
    testvim = mkTestVim system;
  in
  {
    checks = {
      default = self.checks.${system}.drv;
      library = pkgs.callPackage ./library { inherit inputs testvim utils; };
      drv = pkgs.callPackage ./drv { inherit inputs testvim utils; };
      module = pkgs.callPackage ./module { inherit inputs testvim utils; };
    };
  });
}
