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
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
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
      # inherit (OGpkg.passthru) utils;
      # no reason to do that though.
      inherit (nixCats) utils;


      # the result of this override will be your new package
      # after you put your items into it.
      finalPackage = OGpkg.override {
        luaPath = "${./.}";
        inherit nixpkgs system;
        extra_pkg_config = {
          # allowUnfree = true;
        };
        nixCats_passthru = {};

        # dependencyOverlays.${system} = [ (final: prev: {}) ];
        dependencyOverlays = forSystems (system: (
          (import ./overlays inputs) ++ [
            (utils.standardPluginOverlay inputs)
            # other overlays
          ]
        ));

        categoryDefinitions = { pkgs, settings, categories, name, ... }@packageDef: {
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

    in {
      # NOTE:
      # here we will export our packages to
      # packages.${system}.default
      # and packages.${system}.${defaultPackageName}
      default = finalPackage;
      ${defaultPackageName} = finalPackage;
    });

    # NOTE: outputting a dev shell. to devShells.${system}.default
    devShells = forSystems (system: (let
      # this pkgs is only for using pkgs.mkShell
      # and adding various other programs.
      pkgs = import nixpkgs { inherit system; };
      # if you chose to override your nixCats package
      # again here, it has its own pkgs object in
      # packageDefinitions and categoryDefinitions
      # for you to use (see above).
      # You could also use this one though
      # but its better to not mix them for sanity purposes.
      greeting = ''
        Welcome to nixCats!
        (short for nix categories)
        To launch your neovim package,
        use ${defaultPackageName} command!
      '';
    in {
      default = pkgs.mkShell {
        name = defaultPackageName;
        packages = [ self.packages.${system}.default ];
        inputsFrom = [ ];
        shellHook = ''
          ${pkgs.charasay}/bin/chara say -c kitten '${greeting}'
        '';
      };
    }));

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
