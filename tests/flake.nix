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
    libT = pkgs.callPackage ./libT.nix { inherit inputs utils; };

    package = import ./nvim { inherit inputs utils system packagename libT; };

    testargs = { inherit package inputs utils libT stateVersion; };

    drvtests = pkgs.callPackage ./drv testargs;
    hometests = pkgs.callPackage ./home testargs;
  in
  {
    checks = {
      inherit drvtests hometests;
    };
  });
}
