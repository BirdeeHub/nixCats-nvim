# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
/* 
  # paste the inputs you don't have in this set into your main system flake.nix
  # (lazy.nvim wrapper only works on unstable)
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim?dir=nix";
  };

  Then call this file with:
  myNixCats = import ./path/to/this/dir { inherit inputs; };
  And the new variable myNixCats will contain all outputs of the normal flake format.
  You could put myNixCats.packages.${pkgs.system}.thepackagename in your packages list.
  You could install them with the module and reconfigure them too if you want.
  You should definitely re export them under packages.${system}.packagenames
  from your system flake so that you can still run it via nix run from anywhere.

  The following is just the outputs function from the flake template.
 */
{inputs, ... }@attrs: let
  inherit (inputs) nixpkgs; # <-- nixpkgs = inputs.nixpkgsSomething;
  inherit (inputs.nixCats) utils;
  luaPath = "${./.}";
  forEachSystem = utils.eachSystem nixpkgs.lib.platforms.all;
  # the following extra_pkg_config contains any values
  # which you want to pass to the config set of nixpkgs
  # import nixpkgs { config = extra_pkg_config; inherit system; }
  # will not apply to module imports
  # as that will have your system values
  extra_pkg_config = {
    # allowUnfree = true;
  };
  inherit (forEachSystem (system: let
    # see :help nixCats.flake.outputs.overlays
    # This overlay grabs all the inputs named in the format
    # `plugins-<pluginName>`
    # Once we add this overlay to our nixpkgs, we are able to
    # use `pkgs.neovimPlugins`, which is a set of our plugins.
    dependencyOverlays = /* (import ./overlays inputs) ++ */ [
      (utils.standardPluginOverlay inputs)
      # add any flake overlays here.
    ];
  in { inherit dependencyOverlays; })) dependencyOverlays;

  categoryDefinitions = { pkgs, settings, categories, name, ... }@packageDef: {

    propagatedBuildInputs = {
      general = with pkgs; [
      ];
    };

    lspsAndRuntimeDeps = {
      general = with pkgs; [
      ];
    };

    startupPlugins = {
      general = [
      ];
    };

    optionalPlugins = {
      gitPlugins = with pkgs.neovimPlugins; [ ];
      general = with pkgs.vimPlugins; [ ];
    };

    # shared libraries to be added to LD_LIBRARY_PATH
    # variable available to nvim runtime
    sharedLibraries = {
      general = with pkgs; [
        # libgit2
      ];
    };

    environmentVariables = {
      test = {
        CATTESTVAR = "It worked!";
      };
    };

    extraWrapperArgs = {
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
      test = [
        '' --set CATTESTVAR2 "It worked again!"''
      ];
    };

    # lists of the functions you would have passed to
    # python.withPackages or lua.withPackages

    # get the path to this python environment
    # in your lua config via
    # vim.g.python3_host_prog
    # or run from nvim terminal via :!<packagename>-python3
    extraPython3Packages = {
      test = (_:[]);
    };
    # populates $LUA_PATH and $LUA_CPATH
    extraLuaPackages = {
      test = [ (_:[]) ];
    };

  };

  packageDefinitions = {
    nixCats = {pkgs , ... }: {
      # they contain a settings set defined above
      # see :help nixCats.flake.outputs.settings
      settings = {
        wrapRc = true;
        # IMPORTANT:
        # your alias may not conflict with your other packages.
        aliases = [ "vim" ];
        # neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
      };
      # and a set of categories that you want
      # (and other information to pass to lua)
      categories = {
        general = true;
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
  # In this section, the main thing you will need to do is change the default package name
  # to the name of the packageDefinitions entry you wish to use as the default.
    defaultPackageName = "nixCats";
in
  # see :help nixCats.flake.outputs.exports
  forEachSystem (system: let
    nixCatsBuilder = utils.baseBuilder luaPath {
      inherit system dependencyOverlays extra_pkg_config nixpkgs;
    } categoryDefinitions packageDefinitions;
    defaultPackage = nixCatsBuilder defaultPackageName;
    # this is just for using utils such as pkgs.mkShell
    # The one used to build neovim is resolved inside the builder
    # and is passed to our categoryDefinitions and packageDefinitions
    pkgs = import nixpkgs { inherit system; };
  in {
    # this will make a package out of each of the packageDefinitions defined above
    # and set the default package to the one passed in here.
    packages = utils.mkAllWithDefault defaultPackage;

    # choose your package for devShell
    # and add whatever else you want in it.
    devShells = {
      default = pkgs.mkShell {
        name = defaultPackageName;
        packages = [ defaultPackage ];
        inputsFrom = [ ];
        shellHook = ''
        '';
      };
    };

  }) // {

  # these outputs will be NOT wrapped with ${system}

  # this will make an overlay out of each of the packageDefinitions defined above
  # and set the default overlay to the one named here.
  overlays = utils.makeOverlays luaPath {
    # we pass in the things to make a pkgs variable to build nvim with later
    inherit nixpkgs dependencyOverlays extra_pkg_config;
    # and also our categoryDefinitions
  } categoryDefinitions packageDefinitions defaultPackageName;

  # we also export a nixos module to allow reconfiguration from configuration.nix
  nixosModules.default = utils.mkNixosModules {
    inherit defaultPackageName dependencyOverlays luaPath
      categoryDefinitions packageDefinitions extra_pkg_config nixpkgs;
  };
  # and the same for home manager
  homeModule = utils.mkHomeModules {
    inherit defaultPackageName dependencyOverlays luaPath
      categoryDefinitions packageDefinitions extra_pkg_config nixpkgs;
  };
  inherit utils;
  inherit (utils) templates;
}
