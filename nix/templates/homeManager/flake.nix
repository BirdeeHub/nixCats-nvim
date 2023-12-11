{
  description = ''
    My system config
    THIS IS NOT A COMPLETE NIXOS CONFIG FILE!!!
    THIS IS A TEMPLATE FOR JUST HOW TO IMPORT NIXCATS BASED CONFIGS INTO IT

    THIS IS NOT A COMPLETE NIXOS CONFIG FILE!!!
    THIS IS A TEMPLATE FOR JUST HOW TO IMPORT NIXCATS BASED CONFIGS INTO IT

    This is also not the only way to import flakes into configuration.nix
    For other nixCats options not included in this template
    see :help nixCats.flake.outputs.exports.mkHomeModules
  '';
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
  };
  outputs = { self, nixpkgs, home-manager, ... }@inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      # config.allowUnfree = true;
    };
  in {
    homeConfigurations = {
      "REPLACE_ME" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [
          ./home.nix
          inputs.nixCats.homeModule.${system}
        ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
        extraSpecialArgs = {
          inherit self inputs;
        };
      };
    };
  };
}
