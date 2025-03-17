# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
{
  description = ''
    assuming you are at the top level of the repo,
    nix flake check --show-trace -Lv ./tests
  '';
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-appimage.url = "github:ralismark/nix-appimage";
  };
  outputs = { self, nixpkgs, ... }@inputs: let
    utils = import ../.;
    forAllSys = utils.eachSystem nixpkgs.lib.platforms.all;
    nixCats = (let
      nixosModule = utils.mkNixosModules {};
      homeModule = utils.mkHomeModules {};
    in {
      outPath = ../.;
      inherit utils nixosModule homeModule;
      inherit (utils) templates;
      nixosModules.default = nixosModule;
      homeModules.default = homeModule;
    });
  in forAllSys (system: let
    pkgs = import nixpkgs { inherit system; };
    libT = pkgs.callPackage ./libT { inherit inputs utils; };
    callFlake = libT.pureCallFlakeOverride;

    inputswithbase = inputs // { inherit nixCats; };
    exampleflake = callFlake utils.templates.example.path inputswithbase;
    inputswithexample = inputs // { nixCats = exampleflake; };

    exampleconfig = exampleflake.packages.${system}.default;
    kickstartconfig = (callFlake utils.templates.kickstart-nvim.path inputswithbase).packages.${system}.default;
    overriding = (callFlake utils.templates.overriding.path inputswithexample).packages.${system}.default;
    overwrite = (callFlake utils.templates.overwrite.path inputswithexample).packages.${system}.default;
    LazyVim = (callFlake utils.templates.LazyVim.path inputswithbase).packages.${system}.default;
    flakeless = import utils.templates.flakeless.path { inherit pkgs nixCats; };

    testargs = {
      stateVersion = "24.05";
      inherit inputs utils libT;
    };
    testargs1 = testargs // {
      package = import ./nvim {
        packagename = "testvim";
        inherit inputs utils system;
      };
    };
    drvtests = pkgs.callPackage ./drv testargs1;
    hometests = pkgs.callPackage ./home testargs1;
    nixostests = pkgs.callPackage ./nixos testargs1;

    exampledrvtests = pkgs.callPackage ./exampledrv (testargs // {
      package = exampleconfig;
    });
    kickstartdrvtests = pkgs.callPackage ./exampledrv (testargs // {
      package = kickstartconfig;
    });
  in
  {
    libT = libT;
    checks = {
      inherit drvtests hometests nixostests;
      inherit exampledrvtests kickstartdrvtests;
      # sanity template build checks
      inherit overwrite overriding LazyVim flakeless;
    };
  });
}
