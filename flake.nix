# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
{
  description = ''
    # nixCats - nix categories for neovim #

    A neovim package manager written in nix, with normal neovim directory structure,
    easy communication from nix to your neovim configuration,
    and ability to simply categorize dependencies for outputting multiple packages.
  '';
  outputs = _: let
    # everything you will need is in utils.
    utils = import ./utils;
    nixosModule = utils.mkNixosModules {};
    homeModule = utils.mkHomeModules {};
  in {
    inherit utils homeModule nixosModule;
    inherit (utils) templates;
    nixosModules.default = nixosModule;
    homeModules.default = homeModule;
  };
}
