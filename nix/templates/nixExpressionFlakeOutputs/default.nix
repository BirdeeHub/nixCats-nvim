# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license

/*

This is a weird way to import nixCats.
Its actually the one I use. I use it because it allows me to
output all the nixCats things from my system flake, but also
to have it integrated into my main config repo,
and have the same config for system and home-manager.

It has its own problem, the systemPkg thing described below.
However, you should not see any issues if you use the pkgs generated here.

*/

{inputs, ... }@attrs:
(inputs.flake-utils.lib.eachDefaultSystem (system: let
  inherit (inputs) nixpkgs nixCats;
  inherit (nixCats) utils;
  # use of this systemPkg variable should be avoided as
  # it would mean the nvim packages produced
  # may not be as system independent as expected
  systemPkgs = if (attrs ? pkgs) then attrs.pkgs else null;
  # this means you should add any overlays you wish to include for neovim here.

  # this util merges nixCats overlays with this one so we don't have to redefine them
  # you could just provide a list here.
  dependencyOverlays = [ (utils.mergeOverlayLists nixCats.dependencyOverlays.${system}
    ((import ./overlays inputs) ++ [
      (utils.standardPluginOverlay inputs)
      # add any flake overlays here.
    ])
  ) ];
  pkgs = import nixpkgs {
    inherit system;
    overlays = dependencyOverlays;
    # config.allowUnfree = true;
  };

  inherit (utils) baseBuilder;
  nixCatsBuilder = baseBuilder "${./.}" { inherit pkgs dependencyOverlays; } categoryDefinitions packageDefinitions;

  categoryDefinitions = packageDef: {

    propagatedBuildInputs = {
      general = with pkgs; [
      ];
    };

    lspsAndRuntimeDeps = {
      general = with pkgs; [
      ];
    };

    startupPlugins = {
      general = with pkgs.vimPlugins; [
      ];
    };

    optionalPlugins = {
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

  };

  packageDefinitions = {
    nixCats = {
      settings = {
        wrapRc = true;
        # so that it finds my ai auths in ~/.cache/birdeevim
        configDirName = "arbitrary-name";
        viAlias = true;
        vimAlias = true;
      };
      categories = {
        general = true;
        test = true;
      };
    };
  };
in
{
  # packages and overlays here are the same as flake.nix except without the default output
  packages = (builtins.mapAttrs (name: _: nixCatsBuilder name) packageDefinitions);

  overlays = utils.mkExtraOverlays nixCatsBuilder packageDefinitions "nixCats";

  devShell = pkgs.mkShell {
    name = "nixCats";
    packages = [ (nixCatsBuilder "nixCats") ];
    inputsFrom = [ ];
    shellHook = ''
    '';
  };

  # To choose settings and categories from the flake that calls this flake.
  customPackager = baseBuilder "${./.}" { inherit pkgs dependencyOverlays;} categoryDefinitions;

  # and you export this so people dont have to redefine stuff.
  inherit dependencyOverlays;
  inherit categoryDefinitions;
  inherit packageDefinitions;

  # we also export a nixos module to allow configuration from configuration.nix
  nixosModules.default = utils.mkNixosModules {
    defaultPackageName = "nixCats";
    luaPath = "${./.}";
    inherit dependencyOverlays
      categoryDefinitions packageDefinitions;
  };
  # and the same for home manager
  homeModule = utils.mkHomeModules {
    defaultPackageName = "nixCats";
    luaPath = "${./.}";
    inherit dependencyOverlays
      categoryDefinitions packageDefinitions;
  };
}) // {
    inherit (inputs.nixCats) utils;
    inherit (inputs.nixCats.utils) templates baseBuilder;
    keepLuaBuilder = inputs.nixCats.utils.baseBuilder "${./.}";
})

