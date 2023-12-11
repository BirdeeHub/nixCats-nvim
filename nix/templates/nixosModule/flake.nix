{
  description = ''
    My system config
    THIS IS NOT A COMPLETE NIXOS CONFIG FILE!!!
    THIS IS A TEMPLATE FOR JUST HOW TO IMPORT NIXCATS BASED CONFIGS INTO IT

    THIS IS NOT A COMPLETE NIXOS CONFIG FILE!!!
    THIS IS A TEMPLATE FOR JUST HOW TO IMPORT NIXCATS BASED CONFIGS INTO IT

    This is also not the only way to import flakes into configuration.nix
    For other nixCats options not included in this template
    see :help nixCats.flake.outputs.exports.mkNixosModules
  '';
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
  };
  outputs = { self, nixpkgs, ... }@inputs: let
    system = "x86_64-linux";
  in {
    nixosConfigurations = {
      REPLACE_ME = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit self;
          inherit inputs;
        };
        modules = [
          ./configuration.nix
          inputs.nixCats.nixosModules.${system}.default
        ];
      };
    };
  };
}
