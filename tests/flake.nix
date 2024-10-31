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
    packagename = "testvim";
  in forAllSys (system: let
    pkgs = import nixpkgs { inherit system; };
    testvim = import ./nvim { inherit inputs utils system packagename; };
    hometests = pkgs.callPackage ./home { inherit testvim inputs utils; };
    drvtests = pkgs.callPackage ./drv { inherit testvim inputs utils; };
  in
  {
    checks = {
      inherit drvtests hometests;
    };
  });
}
