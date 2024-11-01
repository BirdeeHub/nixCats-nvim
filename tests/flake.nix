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
    stateVersion = "24.05";
  in forAllSys (system: let
    pkgs = import nixpkgs { inherit system; };
    libT = pkgs.callPackage ./libT { inherit inputs utils; };

    package = import ./nvim { inherit inputs utils system packagename; };

    testargs = { inherit package inputs utils libT stateVersion; };

    drvtests = pkgs.callPackage ./drv testargs;
    hometests = pkgs.callPackage ./home testargs;
    nixostests = pkgs.callPackage ./nixos testargs;
  in
  {
    libT = libT;
    checks = {
      inherit drvtests hometests nixostests;
    };
  });
}
