# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
{
  description = ''
    A Lua-natic's neovim flake, with extra cats! nixCats!

    This is a showcase of most of the various utils and builders 
    that get exported and how to use them.

    It does not make use of every option, but it uses most.
    see :help nixCats.flake.outputs.exports for the options used here as well as the rest.

    It would export all the same configurations and exported options as the original 
    but with an extra plugin and a new colorscheme.
    Although its wrapRc option is not useful since the lua is not locally present.
    So it does not export the regularCats package.
    The wrapRc setting is mostly useful for fast iteration while editing lua.
    But it restricts the locations in which you may store the flake to the .config directory.
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";

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
    # This line makes this package availeable for all systems
    # ("x86_64-linux", "aarch64-linux", "i686-linux", "x86_64-darwin",...)
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
      otherOverlays = [ (utils.mergeOverlayLists nixCats.otherOverlays.${system}
        ( (import ./overlays inputs) ++ 
          [
            # add any flake overlays here.
          ]
        )) ];
      # It is important otherOverlays and standardPluginOverlay
      # are defined separately, because we will be exporting
      # the other overlays we defined for ease of use when
      # integrating various versions of your config with nix configs
      # and attempting to redefine certain things for that system.

      pkgs = import nixpkgs {
        inherit system;
        overlays = otherOverlays ++ [
          # And here we apply standardPluginOverlay to our inputs.
          (utils.standardPluginOverlay (nixCats.inputs // inputs))
        ];
        # config.allowUnfree = true;
      };

      # Now that our plugin inputs/overlays and pkgs have been defined,
      # We define a function to facilitate package building for particular categories
      # This allows us to define categories and settings 
      # for our package later and then choose a package.

      # see :help nixCats.flake.outputs.builder
      baseBuilder = nixCats.customBuilders.${system}.fresh;
      nixCatsBuilder = nixCats.customBuilders.${system}.keepLua pkgs
        # notice how it doesn't care that these are defined lower in the file?
        categoryDefinitions packageDefinitions;

      # see :help nixCats.flake.outputs.categories
      # and
      # :help nixCats.flake.outputs.categoryDefinitions.scheme
      categoryDefinitions = utils.mergeCatDefs
        nixCats.categoryDefinitions.${system} (packageDef: {
        # You may use packageDef to further
        # customize the contents of the set returned here per package,
        # based on the info you may include in the packageDefinitions set
        # it contains the packageDefinitions entry for the package currently being built.

        startupPlugins = {
          eyeliner = with pkgs.vimPlugins; [
            eyeliner-nvim
          ];
        };
        optionalLuaAdditions = ''
          if require('nixCats').eyeliner then
            require'eyeliner'.setup {
              highlight_on_key = true,
              dim = true
            }
          end
        '';
        }
      );

      # see :help nixCats.flake.outputs.packageDefinitions
      packageDefinitions = {
        nixCats = {
          settings = nixCats.packageDefinitions.${system}.nixCats.settings;
          categories = 
            nixCats.packageDefinitions.${system}.nixCats.categories 
            // {
              eyeliner = true;
              colorscheme = "tokyonight";
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
      customPackager = nixCats.customBuilders.${system}.keepLua pkgs categoryDefinitions;

      # You may use these to modify some or all of your categoryDefinitions
      customBuilders = {
        fresh = baseBuilder;
        # this has no lua files to include, so instead of
        # keepLua = baseBuilder self;
        # we instead use this to pass on the other lua we inherited
        keepLua = nixCats.customBuilders.${system}.keepLua;
      };
      inherit utils;

      # and you export this so people dont have to redefine stuff.
      inherit otherOverlays;
      inherit categoryDefinitions;
      inherit packageDefinitions;

      # we also export a nixos module to allow configuration from configuration.nix
      nixosModules.default = utils.mkNixosModules {
        defaultPackageName = "nixCats";
        # unfortunately, we do not have a lua path to provide.
        # so instead we provide our keepLuaBuilder
        keepLuaBuilder = nixCats.customBuilders.${system}.keepLua;

        inherit nixpkgs inputs baseBuilder otherOverlays 
          pkgs categoryDefinitions packageDefinitions;
      };
      # and the same for home manager
      homeModule = utils.mkHomeModules {
        defaultPackageName = "nixCats";
        # unfortunately, we do not have a lua path to provide.
        # so instead we provide our keepLuaBuilder
        keepLuaBuilder = nixCats.customBuilders.${system}.keepLua;

        inherit nixpkgs inputs baseBuilder otherOverlays 
          pkgs categoryDefinitions packageDefinitions;
      };
    }
  ); # end of flake utils, which returns the value of outputs
}
