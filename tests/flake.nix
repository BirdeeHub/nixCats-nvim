# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
{
  description = ''
    assuming you are at the top level of the repo,
    nix flake check --show-trace --impure -Lv ./tests
  '';
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

    pureCallFlake = path: let
      bareflake = import "${path}/flake.nix";
      res = bareflake.outputs (inputs // rec {
        self = res // {
          outputs = res;
          outPath = path;
          inputs = builtins.mapAttrs (n: _:
              inputs.${n} or { inherit nixCats self; }.${n} or builtins.throw "Missing input ${n}"
            ) bareflake.inputs;
        };
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
      });
    in res;

    exampleconfig = (pureCallFlake utils.templates.example.path).packages.${system}.default;
    kickstartconfig = (pureCallFlake utils.templates.kickstart-nvim.path).packages.${system}.default;

    testargs2 = {
      inherit inputs utils libT stateVersion;
      package = exampleconfig;
    };
    exampledrvtests = pkgs.callPackage ./exampledrv testargs2;
    testargs3 = {
      inherit inputs utils libT stateVersion;
      package = kickstartconfig;
    };
    kickstartdrvtests = pkgs.callPackage ./exampledrv testargs3;

    testargs = { inherit package inputs utils libT stateVersion; };

    drvtests = pkgs.callPackage ./drv testargs;
    hometests = pkgs.callPackage ./home testargs;
    nixostests = pkgs.callPackage ./nixos testargs;
  in
  {
    libT = libT;
    checks = {
      inherit drvtests hometests nixostests;
      inherit exampledrvtests kickstartdrvtests;
    };
  });
}
