{
  default = {
    path = ./fresh;
    description = "starting point template for making your neovim flake";
  };
  fresh = {
    path = ./fresh;
    description = "starting point template for making your neovim flake";
  };
  module = {
    path = ./module;
    description = ''
      starting point for creating a nixCats module for your system and home-manager
    '';
  };
  nixExpressionFlakeOutputs = {
    path = ./nixExpressionFlakeOutputs;
    description = ''
      how to import as just the outputs section of the flake, so that you can export
      its outputs with your system outputs

      It is best practice to avoid using the system pkgs and its overlays in this method
      as then you could not output packages for systems not defined in your system flake.
      It creates a new one instead to use, just like the flake template does.

      Call it from your system flake and call it with inputs as arguments.

      In my opinion, this is the best one, but probably not the best one to start with if new to nix.
    '';
  };
  luaUtils = {
    path = ./luaUtils;
    description = ''
      A template that includes lua utils for using neovim package managers
      when your config file is not loaded via nix.
    '';
  };
  overlayHub = {
    path = ./overlayHub;
    description = ''
      A template for overlays/default.nix
      :help nixCats.flake.nixperts.overlays
    '';
  };
  overlayFile = {
    path = ./overlayfile;
    description = ''
      A template for an empty overlay file defined as described in
      :help nixCats.flake.nixperts.overlays
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
}
