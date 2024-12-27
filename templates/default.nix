{
  default = {
    path = ./fresh;
    description = "starting point template for making your neovim flake";
  };
  fresh = {
    path = ./fresh;
    description = "starting point template for making your neovim flake";
  };
  example = {
    path = ./example;
    description = "an idiomatic nixCats example configuration using lze for lazy loading and paq.nvim for backup when not using nix";
  };
  module = {
    path = ./module;
    description = ''
      starting point for creating a nixCats module for your system and home-manager

      contains an example home manager module and an example nixos module in
      separate files.
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
    '';
  };
  overwrite = {
    path = ./overwrite;
    description = ''
      How to CONFIGURE nixCats FROM SCRATCH,
      given only an existing nixCats package,
      achieved via the OVERRIDE function.

      Equivalent to the default flake template
      or nixExpressionFlakeOutputs except
      for using overrides

      every nixCats package is a full nixCats-nvim
    '';
  };
  luaUtils = {
    path = ./luaUtils;
    description = ''
      A template that includes lua utils for using neovim package managers
      when your config file is not loaded via nix.
    '';
  };
  kickstart-nvim = {
    path = ./kickstart-nvim;
    description = ''
      The entirety of kickstart.nvim implemented as a nixCats flake.
      With additional nix lsps for editing the nix part.
      This is to serve as the tutorial for using the nixCats lazy wrapper.
    '';
  };
  overriding = {
    path = ./overriding;
    description = ''
      How to RECONFIGURE nixCats WITHOUT DUPLICATION,
      given only an existing nixCats package,
      achieved via the OVERRIDE function.

      In addition, it is also a demonstration of how to export a nixCats configuration
      as an AppImage.

      It is a 2 for 1 example of 2 SEPARATE things one could do.
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
}
