{
  default = {
    path = ./fresh;
    description = "Starting point template for making your Neovim flake";
  };
  fresh = {
    path = ./fresh;
    description = "Starting point template for making your Neovim flake";
  };
  home-manager = {
    path = ./home-manager;
    description = ''
      demonstration of importing and using the nixCats module for Home-Manager
    '';
  };
  nixos = {
    path = ./nixos;
    description = ''
      demonstration of importing and using the nixCats module for NixOS (and nix-darwin)

      same as home manager, but has the options repeated for per-user configurations
    '';
  };
  nixExpressionFlakeOutputs = {
    path = ./nixExpressionFlakeOutputs;
    description = ''
      How to import as just the outputs section of the flake, so that you can export
      its outputs with your system outputs.

      It is best practice to avoid using the system pkgs and its overlays in this method,
      as then you could not output packages for systems not defined in your system flake.
      It creates a new one instead to use, just like the flake template does.

      Call it from your system flake and call it with inputs as arguments.
    '';
  };
  example = {
    path = ./example;
    description = "an idiomatic nixCats example configuration using lze for lazy loading and paq.nvim for backup when not using nix";
  };
  kickstart-nvim = {
    path = ./kickstart-nvim;
    description = ''
      The entirety of kickstart.nvim implemented as a nixCats flake.
      With additional Nix LSPs for editing the nix part.
      This is to serve as the tutorial for using the nixCats lazy wrapper.
    '';
  };
  LazyVim = {
    path = ./LazyVim;
    description = ''
      How to get the LazyVim distribution up and running
      see the kickstart-nvim template for more info on the lazy wrapper or other utilities used.
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
  overriding = {
    path = ./overriding;
    description = ''
      How to RECONFIGURE nixCats WITHOUT DUPLICATION,
      given only an existing nixCats package,
      achieved via the OVERRIDE function.

      In addition, it is also a demonstration of how to export a nixCats configuration
      as an AppImage.

      It is a two-for-one example of two SEPARATE things one could do.
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
