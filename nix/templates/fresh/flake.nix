# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license

# This is an empty nixCats config.
# you may import this template directly into your nvim folder
# and then add plugins to categories here,
# and call the plugins with their default functions
# within your lua, rather than through the nvim package manager's method.
# Use the help, and the example repository https://github.com/BirdeeHub/nixCats-nvim

# It allows for easy adoption of nix,
# while still providing all the extra nix features immediately.
# Configure in lua, check for a few categories, set a few settings,
# output packages with combinations of those categories and settings.

# All the same options you make here will be automatically exported in a form available
# in home manager and in nixosModules, as well as from other flakes.
# each section is tagged with its relevant help section.

{
  description = "A Lua-natic's neovim flake, with extra cats! nixCats!";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";

    # for if you wish to select a particular neovim version
    # neovim = {
    #   url = "github:neovim/neovim";
    #   flake = false;
    # };
    # add this to the settings set later in flake.nix

    # see :help nixCats.flake.inputs
    # If you want your plugin to be loaded by the standard overlay,
    # i.e. if it wasnt on nixpkgs, but doesnt have an extra build step.
    # Then you should name it "plugins-something"
    # If you wish to define a custom build step not handled by nixpkgs,
    # then you should name it in a different format, and deal with that in the
    # overlay defined for custom builds in the overlays directory.
    # for specific tags, branches and commits, see:
    # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#examples

  };

  # see :help nixCats.flake.outputs
  outputs = { self, nixpkgs, flake-utils, nixCats, ... }@inputs: let
    inherit (nixCats) utils;
    luaPath = "${./.}";
    # the following extra_pkg_config contains any values
    # which you want to pass to the config set of nixpkgs
    # import nixpkgs { config = extra_pkg_config; inherit system; }
    # will not apply to module imports
    # as that will have your system values
    extra_pkg_config = {
      # allowUnfree = true;
    };
    # sometimes our overlays require a ${system} to access the overlay.
    # management of this variable is one of the harder parts of using flakes.

    # so I have done it here in an interesting way to keep it out of the way.

    # First, we will define just our overlays per system.
    # later we will pass them into the builder, and the resulting pkgs set
    # will get passed to the categoryDefinitions and packageDefinitions
    # which follow this section.

    # this allows you to use pkgs.${system} whenever you want in those sections
    # without fear.
    system_resolved = flake-utils.lib.eachDefaultSystem (system: let
      # see :help nixCats.flake.outputs.overlays
      standardPluginOverlay = utils.standardPluginOverlay;
      dependencyOverlays = (import ./overlays inputs) ++ [
        # This overlay grabs all the inputs named in the format
        # `plugins-<pluginName>`
        # Once we add this overlay to our nixpkgs, we are able to
        # use `pkgs.neovimPlugins`, which is a set of our plugins.
        (standardPluginOverlay inputs)
        # add any flake overlays here.
        inputs.nixd.overlays.default
      ];
    in {
      # these overlays will be wrapped with ${system}
      # and we will call the same flake-utils function
      # later on to access them.
      inherit dependencyOverlays;
    });
    # see :help nixCats.flake.outputs.categories
    # and
    # :help nixCats.flake.outputs.categoryDefinitions.scheme
    categoryDefinitions = { pkgs, settings, categories, name, ... }@packageDef: {
      # to define and use a new category, simply add a new list to a set here, 
      # and later, you will include categoryname = true; in the set you
      # provide when you build the package using this builder function.
      # see :help nixCats.flake.outputs.packageDefinitions for info on that section.

      # propagatedBuildInputs:
      # this section is for dependencies that should be available
      # at BUILD TIME for plugins. WILL NOT be available to PATH
      # However, they WILL be available to the shell 
      # and neovim path when using nix develop
        propagatedBuildInputs = {
        };

        # lspsAndRuntimeDeps:
        # this section is for dependencies that should be available
        # at RUN TIME for plugins. Will be available to PATH within neovim terminal
        # this includes LSPs
        lspsAndRuntimeDeps = {
        };

        # This is for plugins that will load at startup without using packadd:
        startupPlugins = {
        };

        # not loaded automatically at startup.
        # use with packadd and an autocommand in config to achieve lazy loading
        optionalPlugins = {
        };

        # environmentVariables:
        # this section is for environmentVariables that should be available
        # at RUN TIME for plugins. Will be available to path within neovim terminal
        environmentVariables = {
        };

        # If you know what these are, you can provide custom ones by category here.
        # If you dont, check this link out:
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
        extraWrapperArgs = {
        };

        # lists of the functions you would have passed to
        # python.withPackages or lua.withPackages
        extraPythonPackages = {
        };
        extraPython3Packages = {
        };
        extraLuaPackages = {
        };
      };



      # And then build a package with specific categories from above here:
      # All categories you wish to include must be marked true,
      # but false may be omitted.
      # This entire set is also passed to nixCats for querying within the lua.

      # see :help nixCats.flake.outputs.packageDefinitions
      packageDefinitions = {
        # These are the names of your packages
        # you can include as many as you wish.
        nixCats = {pkgs , ... }: {
          # they contain a settings set defined above
          # see :help nixCats.flake.outputs.settings
          settings = {
            wrapRc = true;
            # IMPORTANT:
            # you may not alias to nvim
            # your alias may not conflict with your other packages.
            aliases = [ "vim" ];
            # nvimSRC = inputs.neovim;
          };
          # and a set of categories that you want
          # (and other information to pass to lua)
          categories = {
            test = true;
            example = {
              youCan = "add more than just booleans";
              toThisSet = [
                "and the contents of this categories set"
                "will be accessible to your lua with"
                "nixCats('path.to.value')"
                "see :help nixCats"
              ];
            };
          };
        };
      };
    in


  # In this section, the main thing you will need to do is change the default package name
  # to the name of the packageDefinitions entry you wish to use as the default.

  # see :help nixCats.flake.outputs.exports
  flake-utils.lib.eachDefaultSystem (system: let
    inherit (utils) baseBuilder;
    inherit (system_resolved) dependencyOverlays;
    customPackager = baseBuilder luaPath {
      inherit nixpkgs system dependencyOverlays extra_pkg_config;
    } categoryDefinitions;
    nixCatsBuilder = customPackager packageDefinitions;
    # this is just for using utils such as pkgs.mkShell
    # The one used to build neovim is resolved inside the builder
    # and is passed to our categoryDefinitions and packageDefinitions
    pkgs = import nixpkgs { inherit system; };
  in
  {
    # these outputs will be wrapped with ${system} by flake-utils.lib.eachDefaultSystem

    # this will make a package out of each of the packageDefinitions defined above
    # and set the default package to the one named here.
    packages = utils.mkPackages nixCatsBuilder packageDefinitions "nixCats";

    # this will make an overlay out of each of the packageDefinitions defined above
    # and set the default overlay to the one named here.
    overlays = utils.mkOverlays nixCatsBuilder packageDefinitions "nixCats";

    # choose your package for devShell
    # and add whatever else you want in it.
    devShell = pkgs.mkShell {
      name = "nixCats";
      packages = [ (nixCatsBuilder "nixCats") ];
      inputsFrom = [ ];
      shellHook = ''
      '';
    };

    # To choose settings and categories from the flake that calls this flake.
    # and you export overlays so people dont have to redefine stuff.
    inherit customPackager;
    dependencyOverlays = dependencyOverlays.${system};
  }) // {

    # these outputs will be NOT wrapped with ${system}

    # we also export a nixos module to allow configuration from configuration.nix
    nixosModules.default = utils.mkNixosModules {
      defaultPackageName = "nixCats";
      inherit (system_resolved) dependencyOverlays;
      inherit luaPath categoryDefinitions packageDefinitions nixpkgs;
    };
    # and the same for home manager
    homeModule = utils.mkHomeModules {
      defaultPackageName = "nixCats";
      inherit (system_resolved) dependencyOverlays;
      inherit luaPath categoryDefinitions packageDefinitions nixpkgs;
    };
    # now we can export some things that can be imported in other
    # flakes, WITHOUT needing to use a system variable to do it.
    # and update them into the rest of the outputs returned by the
    # eachDefaultSystem function.
    inherit utils;
    inherit (utils) templates baseBuilder;
    inherit categoryDefinitions;
    inherit packageDefinitions;
    keepLuaBuilder = utils.baseBuilder luaPath;
  };

}
