{
  default = {
    path = ./fresh;
    description = "starting point template for making your neovim flake";
  };
  fresh = {
    path = ./fresh;
    description = "starting point template for making your neovim flake";
  };
  nixosModule = {
    path = ./nixosModule;
    description = ''
      An EXAMPLE nixOS module configuration template
    '';
  };
  homeModule = {
    path = ./homeManager;
    description = ''
      An EXAMPLE Home Manager module configuration template
    '';
  };
  kickstart-nvim = {
    path = ./kickstart-nvim;
    description = ''
      The entirety of the main init.lua file implemented as a nixCats flake.
      With additional nix items for sanity.
      This is to serve as the tutorial for using the nixCats lazy wrapper.
    '';
  };
  mergeFlakeWithExisting = {
    path = ./touchUpExisting;
    description = ''
      An EXAMPLE template showing how to merge in parts of other nixCats repos.
    '';
  };
  LSPs = {
    path = ./LSPs;
    description = ''
      An EXAMPLE template showing how to merge in parts of other nixCats repos.
    '';
  };
  luaUtils = {
    path = ./luaUtils;
    description = ''
      A template that includes lua utils for using neovim package managers
      when your config file is not loaded via nix.
    '';
  };
  overlayfile = {
    path = ./overlayfile;
    description = ''
      A template for an empty overlay file defined as described in
      :help nixCats.flake.nixperts.overlays and overlays/default.nix
    '';
  };
}
