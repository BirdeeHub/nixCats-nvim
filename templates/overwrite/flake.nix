{
  description = ''
    Any package based on nixCats is a full nixCats.

    This is how to create a brand new config,
    when all you have is a configured nixCats package.
    Using only the override function

    This is akin to the fresh flake template,
    but using the override function.

    all available arguments to override:
    luaPath categoryDefinitions packageDefinitions name
    nixpkgs system extra_pkg_config dependencyOverlays nixCats_passthru;
  '';
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim?dir=templates/example";
    nixCats.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, nixCats, ... }@inputs: let
    forSystems = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
    # We could hardcode this but this is nice and good for demonstration as well
    defaultPackageName = "nvim";
  in {
    # packages.${system} = { default = finalPackage, nvim = finalPackage; }
    packages = forSystems (system: let

      # NOTE: we will be using only this 1 package from the nixCats repo from here on.
      # This technique works ANYWHERE you can get a nixCats based package.
      OGpkg = nixCats.packages.${system}.default;
      # NOTE: You could, for example, add the overlay from nixCats to your pkgs in your system flake.nix
      # and then grab pkgs.nixCats in a module and reconfigure this same way.
      # then put it in home.packages instead of exporting from the flake like this.
      # we can even get our utils from it:
      # inherit (OGpkg) utils;
      # no reason to do that though here.
      inherit (nixCats) utils;


      # NOTE: the result of this override will be your new package
      # after you put your items into it.
      finalPackage = OGpkg.override {
        luaPath = "${./.}";
        inherit nixpkgs system;
        extra_pkg_config = {
          # allowUnfree = true;
        };
        nixCats_passthru = {};

        dependencyOverlays = [
          (utils.standardPluginOverlay inputs)
          # other overlays
        ];

        categoryDefinitions = { pkgs, settings, categories, extra, name, mkPlugin, ... }@packageDef: {
          # NOTE: for all available fields, see:
          # :help nixCats.flake.outputs.categories
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
          environmentVariables = {
            general = {
              TESTVAR = "It worked!";
            };
          };
        };

        # see :help nixCats.flake.outputs.packageDefinitions
        packageDefinitions = {
          ${defaultPackageName} = { pkgs, ... }: {
            settings = {
              # NOTE: see :help nixCats.flake.outputs.settings
              aliases = [ "vi" "vim" ];
            };
            categories = {
              # NOTE: see :help nixCats.flake.outputs.packageDefinitions
              general = true;
              # NOTE:
              # see :help nixCats
              # you can pass anything that isnt an uncalled nix function
              # into this set, and it will be accessible via the
              # nixCats global command. For this flake,
              # nixCats('general') would equal true.
              # but you can, again, pass in ANYTHING that isnt an
              # uncalled nix function.
              # the settings set and list of installed plugins
              # are also made available via the nixCats plugin
            };
          };
          configNotIncluded = { pkgs, ... }: {
            settings = {
              suffix-path = true;
              suffix-LD = true;
              # NOTE: see :help nixCats.flake.outputs.settings
              # This one wont bundle config.
              # it will look in ~/.config/nvim by default
              wrapRc = false;
              aliases = [ "videv" ];
            };
            categories = {
              # NOTE: here, we will have the same categories as the main package
              # because this one will be used to have quick iteration
              # while editing lua, and we want all the same things available
              # for that purpose. Feel free to factor these out if you wish.
              general = true;
              # NOTE:
              # see :help nixCats
            };
          };
          # NOTE: remember, you can have as many as you want with different things in each
        };

        # NOTE:
        # the package from packageDefinitions to build.
        name = defaultPackageName;
      };
      # NOTE: we can call override as many times as we want.
      # so if we define multiple items in packageDefinitions,
      # we can build this one, and then override it with the other name after
      # which will leave you with both packages.
      # i.e. otherPackage = finalPackage.override { name = "otherPackageName"; };
      # and then both finalPackage and otherPackage will be useable and installable
      # you can do this with any of the fields above, and utility functions
      # are provided for easily merging old values with new ones if desired.

      # NOTE: we could have done all of this overriding in our main config,
      # in a separate module, in a dev shell, etc. This one is in a flake.
      # Ok, we have our package. We could override it again, add it to home.packages
      # or export it from a flake, or even grab finalPackage.passthru.homeModule
      # and reconfigure it in that home module, which will be in the namespace
      # config.${packageName} = { enable = true; <see :help nixCats.module> };

    # will make a set containing all the packages by name,
    # and a default package containing the package we passed in.
    in utils.mkAllWithDefault finalPackage);

    # NOTE: we can still also export everything relevant from before!
    homeModule = self.packages.x86_64-linux.default.homeModule;
    nixosModules.default = self.packages.x86_64-linux.default.nixosModule;
    # NOTE: The system we chose here doesnt matter.
    # the modules recieve it on import,
    # and in the overlay packages below it
    # will be overridden by prev.system
    overlays = (let
      package = self.packages.x86_64-linux.default;
      inherit (package) utils;
    in {
      # default contains all the packages
      default = utils.easyMultiOverlay package;
      # the named ones each contain one of them on its own.
    } // (utils.easyNamedOvers package));

    # NOTE: outputting a dev shell. to devShells.${system}.default
    devShells = forSystems (system: (let
      # NOTE: this pkgs is only for using pkgs.mkShell
      # and adding various other programs.
      pkgs = import nixpkgs { inherit system; };

      # NOTE: We are going to instead choose the unwrapped config
      # for our dev shell, which will find the lua locally for fast iteration
      configNotIncludedVim = self.packages.${system}.default.override (prev: {
        name = "configNotIncluded";
        # NOTE: if you chose to override more things here,
        # It has its own pkgs object in
        # packageDefinitions and categoryDefinitions
        # for you to use (see above, its the same).
        # You could also use the dev shell one, but
        # its better to not mix them for sanity purposes.
        
        # NOTE: There are helper functions in utils for merging
        # the previous definitions when overriding so that
        # you do not need to redefine everything in a package definition
        # or in the categoryDefinitions.
        # :h nixCats.flake.outputs.exports
        # contains a list of functions in the utils set.
        # and there are templates that demonstrate this in depth
      });
      greeting = ''
        Welcome to nixCats!
        (short for nix categories)

        This particular package has been
        configured to be ran via
        `videv` or `configNotIncluded` commands.

        While the main package exported by our flake
        bundles its config, this one did not due to wrapRc = false!
        It will look in ~/.config/nvim by default
        but this can be changed in settings to anywhere.
        This is great for iterating on your lua changes as normal.
        When you are done, rebuild and go back to the normal package
        with the bundled config that can be ran via nix run from anywhere!
      '';
    in {
      default = pkgs.mkShell {
        name = defaultPackageName;
        packages = [ configNotIncludedVim ];
        inputsFrom = [ ];
        shellHook = ''
          ${pkgs.charasay}/bin/chara say -c kitten '${greeting}'
        '';
      };
    }));
  };
}
