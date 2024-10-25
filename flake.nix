# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
{
  description = ''
    A neovim-on-nix config framework for Lua-natic's, with extra cats! nixCats!
  '';
  outputs = { self, ... }: let
    # everything you will need is in utils.
    utils = import ./.;
  in {
    inherit utils;
    inherit (utils) templates;
    nixosModule = utils.mkNixosModules {
      defaultPackageName = "nixCats";
    };
    homeModule = utils.mkHomeModules {
      defaultPackageName = "nixCats";
    };
    nixosModules.default = self.nixosModules.default;
    homeModules.default = self.homeModules.default;
  };

}
