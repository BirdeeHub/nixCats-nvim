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
    nix-appimage.url = "github:ralismark/nix-appimage";
  };
  outputs = { self, nixpkgs, ... }@inputs: let
    utils = import ../.;
    forAllSys = utils.eachSystem nixpkgs.lib.platforms.all;
    packagename = "testvim";
    stateVersion = "24.05";
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

    package = import ./nvim { inherit inputs utils system packagename; };

    pureCallFlake = nixCats: path: let
      bareflake = import "${path}/flake.nix";
      res = bareflake.outputs (inputs // rec {
        self = res // {
          outputs = res;
          outPath = path;
          inputs = builtins.mapAttrs (n: _:
              inputs.${n} or { inherit nixCats self; }.${n} or builtins.throw "Missing input ${n}"
            ) bareflake.inputs;
        };
        inherit nixCats;
      });
    in res;

    exampleflake = (pureCallFlake nixCats utils.templates.example.path);
    exampleconfig = exampleflake.packages.${system}.default;
    kickstartconfig = (pureCallFlake nixCats utils.templates.kickstart-nvim.path).packages.${system}.default;
    overriding = (pureCallFlake exampleflake utils.templates.overriding.path).packages.${system}.default;
    overwrite = (pureCallFlake exampleflake utils.templates.overwrite.path).packages.${system}.default;
    LazyVim = (pureCallFlake nixCats utils.templates.LazyVim.path).packages.${system}.default;
    flakeless = import ../templates/flakeless { inherit pkgs nixCats; };

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
      # sanity template build checks
      inherit overwrite overriding LazyVim flakeless;
    };
  });
}
