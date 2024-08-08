{
  description = ''
    Any package based on nixCats is a full nixCats.

    This is how to create a brand new config,
    when all you have is a configured nixCats package.
    Using only the override function

    This is akin to the fresh flake template,
    but using the override function.
    It also only outputs the package. But that is
    all you need anyway

    all available arguments to override:
    luaPath categoryDefinitions packageDefinitions name
    nixpkgs system extra_pkg_config dependencyOverlays nixCats_passthru;
  '';
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
    nixCats.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, nixCats, ... }@inputs: let
    forSystems = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
  in {
    # packages.${system} = { default = finalPackage, nvim = finalPackage; }
    packages = forSystems (system: let

      # NOTE: we will be using only this 1 package from the nixCats repo from here on.
      # This technique works ANYWHERE you can get a nixCats based package.
      OGpkg = nixCats.packages.${system}.default;
      # NOTE: You could, for example, add the overlay from nixCats to your pkgs in your system flake.nix
      # and then grab pkgs.nixCats in a module and reconfigure this same way.
      # then put it in home.packages instead of exporting from the flake like this.

      # we can even get our utils from it
      inherit (OGpkg.passthru) utils;

      # the result of this override will be your new package
      # after you put your items into it.
      finalPackage = OGpkg.override {
        luaPath = "${./.}";
        inherit nixpkgs system;
        extra_pkg_config = {
          # allowUnfree = true;
        };
        nixCats_passthru = {};

        dependencyOverlays = forSystems (system: (
          (import ./overlays inputs) ++ [
            (utils.standardPluginOverlay inputs)
            # other overlays
          ]
        ));

        categoryDefinitions = { pkgs, settings, categories, name, ... }@packageDef: {
          # for all available fields, see:
          # see :help nixCats.flake.outputs.categories
          startupPlugins = with pkgs.vimPlugins; {
            general = [ ];
          };
          optionalPlugins = with pkgs.vimPlugins; {
            general = [ ];
          };
          lspsAndRuntimeDeps = with pkgs; {
            general = [ ];
          };
          sharedLibraries = with pkgs; {
            general = [ ];
          };
          extraPython3Packages = {
            general = (_:[]);
          };
          extraLuaPackages = {
            general = [ (_:[]) ];
          };
        };

        # see :help nixCats.flake.outputs.packageDefinitions
        packageDefinitions = {
          nvim = { pkgs, ... }: {
            settings = {
              # see :help nixCats.flake.outputs.settings
              aliases = [ "vi" "vim" ];
            };
            categories = {
              # see :help nixCats.flake.outputs.packageDefinitions
              general = true;
              # and :help nixCats
            };
          };
        };

        # NOTE:
        # the package from packageDefinitions to build.
        name = "nvim";
        # we can call override as many times as we want.
        # so if we define multiple items in packageDefinitions,
        # we can build this one, and then override it with the other name
        # which will leave you with both packages.
      };

      # Ok, we have our package. We could override it again, add it to home.packages
      # or export it from a flake, or even grab finalPackage.passthru.homeModule
      # and reconfigure it in that home module, which will be in the namespace
      # config.${packageName} = { enable = true; <see :help nixCats.module> };

    in {
      # NOTE:
      # here we will export our packages to
      # packages.${system}.default
      # and packages.${system}.nvim
      default = finalPackage;
      nvim = finalPackage;
      # or maybe you did the override in a home module!
      # then you could add to home.packages
    });

    # NOTE: we can still also export everything relevant from before!
    homeModule = self.packages.x86_64-linux.default.passthru.homeModule;
    nixosModules.default = self.packages.x86_64-linux.default.passthru.nixosModule;

    overlays = (let
      package = self.packages.x86_64-linux.default;
      inherit (package.passthru) utils;
    in {
      default = utils.easyMultiOverlay package;
    } // (utils.easyNamedOvers package));
    # NOTE: The system we choose here doesnt matter.
    # the modules recieve it on import,
    # and in the overlay packages it
    # will be overridden by prev.system
  };
}
