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
# each section is tagged with it's relevant help section.

{
  description = "A Lua-natic's neovim flake, with extra cats! nixCats!";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixCats.url = "github:BirdeeHub/nixCats";

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
  outputs = { self, nixpkgs, flake-utils, nixCats, ... }@inputs:
    # This line makes this package available for all major systems
    # system is just a string like "x86_64-linux" or "aarch64-darwin"
    flake-utils.lib.eachDefaultSystem (system: let
      utils = nixCats.utils.${system};

      # see :help nixCats.flake.outputs.overlays
      # This function grabs all the inputs named in the format
      # `plugins-<pluginName>` and returns an overlay containing them.
      # Once we add this overlay to our nixpkgs, we are able to
      # use `pkgs.neovimPlugins`, which is a set of our plugins.
      standardPluginOverlay = utils.standardPluginOverlay;

      # you may define more overlays in the overlays directory, and import them
      # in the default.nix file in that directory.
      # see overlays/default.nix for how to add more overlays in that directory.
      # or see :help nixCats.flake.nixperts.overlays
      otherOverlays = (import ./overlays inputs) ++ [
        # add any flake overlays here.
      ];
      # It is important otherOverlays and standardPluginOverlay
      # are defined separately, because we will be exporting
      # the other overlays we defined for ease of use when
      # integrating various versions of your config with nix configs
      # and attempting to redefine certain things for that system.

      pkgs = import nixpkgs {
        inherit system;
        overlays = otherOverlays ++ [
          # And here we apply standardPluginOverlay to our inputs.
          (standardPluginOverlay inputs)
        ];
        # config.allowUnfree = true;
      };

      # Now that our plugin inputs/overlays and pkgs have been defined,
      # We define a function to facilitate package building for particular categories
      # This allows us to define categories and settings 
      # for our package later and then choose a package.

      # see :help nixCats.flake.outputs.builder
      baseBuilder = nixCats.customBuilders.${system}.fresh;
      nixCatsBuilder = baseBuilder self pkgs
        # notice how it doesn't care that these are defined lower in the file?
        categoryDefinitions packageDefinitions;

      # see :help nixCats.flake.outputs.categories
      categoryDefinitions = packageDef: {
        # The top level sets are not arbitrary,
        # they define what you can provide categories of.
        # However, the categories within very much are arbitrary.
        # simply add a new list to a set here,
        # and later, you will include categoryname = true; in the set you
        # provide when you build the package using this builder function.
        # see :help nixCats.flake.outputs.packageDefinitions for info on that section.

        # You may use packageDefinitions.${name} to further
        # customize the contents of the set returned here per package,
        # based on the info you may include in the packageDefinitions set,
        # and the name of the package currently being built.

        # propagatedBuildInputs:
        # this section is for dependencies that should be available
        # at BUILD TIME for plugins. WILL NOT be available to PATH
        # However, they WILL be available to the shell 
        # and neovim path when using nix develop
        propagatedBuildInputs = {
          # remember these categories are arbitrary
          # we will include them by name per package as desired
          # make as many lists as you want to.
          general = with pkgs; [
          ];
        };

        # lspsAndRuntimeDeps:
        # this section is for dependencies that should be available
        # at RUN TIME for plugins. Will be available to PATH within neovim terminal
        # this includes LSPs
        lspsAndRuntimeDeps = {
          general = with pkgs; [
          ];
        };

        # This is for plugins that will load at startup without using packadd:
        startupPlugins = {
          general = with pkgs.vimPlugins; [
          ];
          # themer = with pkgs.vimPlugins; [
          #   # You can retreive information from the
          #   # packageDefinitions of the package this was packaged with.
          #   # you can use it to create something like subcategories
          #   # that could still be set by customPackager
          #   (builtins.getAttr packageDef.categories.colorscheme {
          #       # Theme switcher without creating a new category
          #       "onedark" = onedark-vim;
          #       "catppuccin" = catppuccin-nvim;
          #       "catppuccin-mocha" = catppuccin-nvim;
          #       "tokyonight" = tokyonight-nvim;
          #       "tokyonight-day" = tokyonight-nvim;
          #     }
          #   )
          #   # This is obviously a fairly basic usecase for this, but still nice.
          #   # Better would be something like:
          #   # language specific packaging that still keeps debuggers in the debugger category
          #   # or excluding something within a category from only one or 2 packages.
          #
          #   # Checking packageDefinitions also has the bonus
          #   # of being able to be easily set by importing flakes.
          # ];
        };

        # not loaded automatically at startup.
        # use with packadd and an autocommand in config to achieve lazy loading
        optionalPlugins = {
        };

        # environmentVariables:
        # this section is for environmentVariables that should be available
        # at RUN TIME for plugins. Will be available to path within neovim terminal
        environmentVariables = {
          test = {
            CATTESTVAR = "It worked!";
          };
        };

        # If you know what these are, you can provide custom ones by category here.
        # If you dont, check this link out:
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
        extraWrapperArgs = {
          test = [
            '' --set CATTESTVAR2 "It worked again!"''
          ];
        };

        extraPythonPackages = {
          test = [ (_:[]) ];
        };
        extraPython3Packages = {
          test = [ (_:[]) ];
        };
        extraLuaPackages = {
          test = [ (_:[]) ];
        };
      };

      # see :help nixCats.flake.outputs.settings
      settings = {
        nixCats = {
          # This folder is ran from the nix store
          # if wrapRc = true;
          wrapRc = true;
          viAlias = false;
          vimAlias = true;
          # nvimSRC = inputs.neovim;
        };
        unwrappedLua = {
          # However, wrapRc = false will make it
          # look inside your .config directory
          wrapRc = false;
          viAlias = false;
          vimAlias = true;
        };
      };


      # And then build a package with specific categories from above here:
      # All categories you wish to include must be marked true,
      # but false may be omitted.
      # This entire set is also passed to nixCats for querying within the lua.
      # It is passed as a Lua table with values name = boolean. same as here.

      # see :help nixCats.flake.outputs.packageDefinitions
      packageDefinitions = {
        # These are the names of your packages
        nixCats = {
          # they contain a settings set defined above
          settings = settings.nixCats; 
          # and a set of categories that you want
          # (and other information to pass to lua)
          categories = {
            general = true;
            # themer = true;
            # colorscheme = onedark;
            test = true;
            example = {
              youCan = "add more than just booleans";
              toThisSet = [
                "and the contents of this categories set"
                "will be accessible to your lua with"
                "require('nixCats')"
                "booleans and null will be converted"
                "sets and lists are recursively evaluated"
                "everything else will become a string"
              ];
            };
          };
        };
        regularCats = { 
          settings = settings.unwrappedLua;
          categories = {
            # themer = true;
            # colorscheme = catppuccin;
            general = true;
            test = true;
          };
        };
      };
    in



    # see :help nixCats.flake.outputs.exports
    {
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
      customPackager = baseBuilder self pkgs categoryDefinitions;

      # You may use these to modify some or all of your categoryDefinitions
      customBuilders = {
        fresh = baseBuilder;
        keepLua = baseBuilder self;
      };
      inherit utils;

      # and you export this so people dont have to redefine stuff.
      inherit otherOverlays;
      inherit categoryDefinitions;
      inherit packageDefinitions;

      # we also export a nixos module to allow configuration from configuration.nix
      nixosModules.default = utils.mkNixosModules {
        defaultPackageName = "nixCats";
        luaPath = "${self}";
        inherit nixpkgs inputs baseBuilder otherOverlays 
          pkgs categoryDefinitions packageDefinitions;
      };
      # and the same for home manager
      homeModule = utils.mkHomeModules {
        defaultPackageName = "nixCats";
        luaPath = "${self}";
        inherit nixpkgs inputs baseBuilder otherOverlays 
          pkgs categoryDefinitions packageDefinitions;
      };

    }
  ); # end of flake utils, which returns the value of outputs
}
