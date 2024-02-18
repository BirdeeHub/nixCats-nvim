# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
/*
Call this file with an inputs set containing nixCats, flake-utils and nixpkgs
and recieve a set of flake outputs to pass anywhere you want.
*/
{inputs, ... }@attrs: let
  inherit (inputs) flake-utils nixpkgs;
  inherit (inputs.nixCats) utils;
  luaPath = "${./.}";
  forEachSystem = flake-utils.lib.eachSystem flake-utils.lib.allSystems;
  # the following extra_pkg_config contains any values
  # which you want to pass to the config set of nixpkgs
  # import nixpkgs { config = extra_pkg_config; inherit system; }
  # will not apply to module imports
  # as that will have your system values
  extra_pkg_config = {
    # allowUnfree = true;
  };
  system_resolved = forEachSystem (system: let
    # see :help nixCats.flake.outputs.overlays
    # This overlay grabs all the inputs named in the format
    # `plugins-<pluginName>`
    # Once we add this overlay to our nixpkgs, we are able to
    # use `pkgs.neovimPlugins`, which is a set of our plugins.
    dependencyOverlays = [ (utils.mergeOverlayLists inputs.nixCats.dependencyOverlays.${system}
    ((import ./overlays inputs) ++ [
      (utils.standardPluginOverlay inputs)
      # add any flake overlays here.
    ])) ];
  in { inherit dependencyOverlays; });
  inherit (system_resolved) dependencyOverlays;

  categoryDefinitions = { pkgs, settings, categories, name, ... }@packageDef: {

    propagatedBuildInputs = {
      generalBuildInputs = with pkgs; [
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
      customPlugins = with pkgs.nixCatsBuilds; [ ];
      gitPlugins = with pkgs.neovimPlugins; [ ];
      general = with pkgs.vimPlugins; [ ];
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
    extraPythonPackages = {
      test = (_:[]);
    };
    extraPython3Packages = {
      test = (_:[]);
    };
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
        # you may not alias to nvim
        # your alias may not conflict with your other packages.
        aliases = [ "vim" ];
        # nvimSRC = inputs.neovim;
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
    inherit (utils) baseBuilder;
    customPackager = baseBuilder luaPath {
      inherit system dependencyOverlays extra_pkg_config nixpkgs;
    } categoryDefinitions;
    nixCatsBuilder = customPackager packageDefinitions;
    # this is just for using utils such as pkgs.mkShell
    # The one used to build neovim is resolved inside the builder
    # and is passed to our categoryDefinitions and packageDefinitions
    pkgs = import nixpkgs { inherit system; };
  in {
    # this will make a package out of each of the packageDefinitions defined above
    # and set the default package to the one named here.
    packages = utils.mkPackages nixCatsBuilder packageDefinitions defaultPackageName;

    # this will make an overlay out of each of the packageDefinitions defined above
    # and set the default overlay to the one named here.
    overlays = utils.mkOverlays nixCatsBuilder packageDefinitions defaultPackageName;

    # choose your package for devShell
    # and add whatever else you want in it.
    devShell = pkgs.mkShell {
      name = defaultPackageName;
      packages = [ (nixCatsBuilder defaultPackageName) ];
      inputsFrom = [ ];
      shellHook = ''
      '';
    };

    # To choose settings and categories from the flake that calls this flake.
    # and you export overlays so people dont have to redefine stuff.
    inherit customPackager;
  }
) // {
  # we also export a nixos module to allow configuration from configuration.nix
  nixosModules.default = utils.mkNixosModules {
    inherit defaultPackageName dependencyOverlays luaPath
      categoryDefinitions packageDefinitions nixpkgs;
  };
  # and the same for home manager
  homeModule = utils.mkHomeModules {
    inherit defaultPackageName dependencyOverlays luaPath
      categoryDefinitions packageDefinitions nixpkgs;
  };
  # now we can export some things that can be imported in other
  # flakes, WITHOUT needing to use a system variable to do it.
  # and update them into the rest of the outputs returned by the
  # eachDefaultSystem function.
  inherit utils categoryDefinitions packageDefinitions dependencyOverlays;
  inherit (utils) templates baseBuilder;
  keepLuaBuilder = utils.baseBuilder luaPath;
}
