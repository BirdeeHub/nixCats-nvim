{
  default = {
    path = ./fresh;
    description = ''
      Starting point template for making your Neovim flake.
      This is the same as the `fresh` flake template.
    '';
  };
  fresh = {
    path = ./fresh;
    description = ''
      Starting point template for making your Neovim flake.
    '';
  };
  home-manager = {
    path = ./home-manager;
    description = ''
      Demonstration of importing and using the nixCats module for Home Manager.
    '';
  };
  nixos = {
    path = ./nixos;
    description = ''
      Demonstration of importing and using the nixCats module for NixOS (and nix-darwin).

      Same as the `home-manager` template, but has the options repeated for per-user configurations.
    '';
  };
  nixExpressionFlakeOutputs = {
    path = ./nixExpressionFlakeOutputs;
    description = ''
      How to import as just the outputs section of the flake, so that you can export
      its outputs with your system outputs.

      It is best practice to avoid using the system pkgs and its overlays in this method,
      as then you could not output packages for systems not defined in your system flake.
      It creates a new one instead to use, just like the `fresh` flake template does.

      Call it from your system flake and call it with inputs as arguments.
    '';
  };
  flakeless = {
    path = ./flakeless;
    description = ''
      nixCats starter template without flakes, as a simple nix expression.
      Returns just a nixCats neovim derivation with your config.

      You may use `.override` on the returned package
      to change which package you are building from your packageDefinitions by changing `name`.

      There are other tricks you can do with override too!
      Every package is its own nixCats, but with its own base configuration!
    '';
  };
  example = {
    path = ./example;
    description = ''
      An idiomatic nixCats example configuration using
      lze for lazy loading and paq.nvim for backup when not using nixCats-nvim.

      See also [templates/example/README.md](https://github.com/BirdeeHub/nixCats-nvim/tree/main/templates/example/README.md).
      '';
  };
  kickstart-nvim = {
    path = ./kickstart-nvim;
    description = ''
      The entirety of kickstart.nvim implemented as a nixCats flake.
      With additional Nix LSPs for editing the Nix part.
      This is to serve as the tutorial for using the nixCats lazy wrapper.

      See also [templates/kickstart-nvim/README.md](https://github.com/BirdeeHub/nixCats-nvim/tree/main/templates/kickstart-nvim/README.md).
    '';
  };
  LazyVim = {
    path = ./LazyVim;
    description = ''
      How to get the LazyVim distribution up and running.
      See the `kickstart-nvim` template for more info on the lazy wrapper or other utilities used.
    '';
  };
  overwrite = {
    path = ./overwrite;
    description = ''
      How to CONFIGURE nixCats FROM SCRATCH,
      given only an existing nixCats package,
      achieved via the OVERRIDE function.

      Equivalent to the default flake template
      or `nixExpressionFlakeOutputs` except
      for using overrides.

      Every nixCats package is a full nixCats-nvim.
    '';
  };
  luaUtils = {
    path = ./luaUtils;
    description = ''
      A template that includes Lua utils for using Neovim package managers
      when your config file is not loaded via Nix.
    '';
  };
  simple = {
    path = ./simple;
    description = ''
      This is approximately as minimal of a configuration as possible without missing major functionality,
      and is split up into multiple files for easy reading.

      Just like the `flakeless` template, it is a nix expression that returns a derivation containing
      neovim plus your configuration that can be installed like any other package.

      This configuration does not make much use of the category system. Everything is in 1 single `general` category.

      It also does not lazily load its plugins.

      If you are new to nvim and lua and maybe even nix, and everything else is too confusing, this may help!
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
      A template for overlays/default.nix.
      See `:help nixCats.flake.nixperts.overlays`.
    '';
  };
  overlayFile = {
    path = ./overlayfile;
    description = ''
      A template for an empty overlay file defined as described in
      `:help nixCats.flake.nixperts.overlays`.
    '';
  };
}
