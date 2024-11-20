# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
builtins.throw ''
  The following arguments are accepted:

  # -------------------------------------------------------- #

  # the path to your ~/.config/nvim replacement within your nix config.
  luaPath: # <-- must be a store path

  { # set of items for building the pkgs that builds your neovim

    , nixpkgs # <-- required
    , system # <-- required

    # type: (attrsOf listOf overlays) or (listOf overlays) or null
    , dependencyOverlays ? null 

    # import nixpkgs { config = extra_pkg_config; inherit system; }
    , extra_pkg_config ? {} # type: attrs

    # any extra stuff for finalPackage.passthru
    , nixCats_passthru ? {} # type: attrs
  }:

  # type: function with args { pkgs, settings, categories, name, extra, mkNvimPlugin, ... }:
  # returns: set of sets of categories
  # see :h nixCats.flake.outputs.categories
  categoryDefinitions: 

  # type: function with args { pkgs, mkNvimPlugin, ... }:
  # returns: { settings = {}; categories = {}; extra = {}; }
  packageDefinitions: 
  # see :h nixCats.flake.outputs.packageDefinitions
  # see :h nixCats.flake.outputs.settings

  # name of the package to built from packageDefinitions
  name: 

  # -------------------------------------------------------- #

  # Note:
  When using override, all values shown above will
  be top level attributes of prev, none will be nested.

  i.e. finalPackage.override (prev: { inherit (prev) dependencyOverlays; })
    NOT prev.pkgsargs.dependencyOverlays or something like that
''
