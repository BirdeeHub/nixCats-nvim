# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
{
  description = ''
    This is an example of how to modify a nixCats-based config further
    upon importing one that has already been configured.
    The modules are also able to be used to extend an existing nixCats configuration.
    They use these same mechanisms internally to achieve this.

    It is also an example of how to export an AppImage based on a configuration.

    You could do the same things in a base configuration to export the AppImage,
    you do not need to re import an existing one like this to do so.
    I did not want to include nix-appimage as a dependency of the main example config.

    So here, we get a 2 for 1 example. Both how to modify an already configured nixCats config
    and ALSO how to export any configuration as an AppImage.
  '';
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
    nixCats.inputs.nixpkgs.follows = "nixpkgs";
    # we are going to modify the example nixCats config to export
    # an appimage using this bunder tool.
    nix-appimage.url = "github:ralismark/nix-appimage";
  };

  outputs = { self, nixpkgs, nixCats, nix-appimage, ... }@inputs: let
    inherit (nixCats) utils;
    # NOTE: We define no luaPath here.
    # We will instead use the lua configuration from the main nixCats example config.
    # We will do this via the keepLuaBuilder exported by the main nixCats example config.
    forEachSystem = utils.eachSystem nixpkgs.lib.platforms.all;
    extra_pkg_config = {
      # allowUnfree = true;
    };
    inherit (forEachSystem (system: let
      # NOTE: we use mergeOverlayLists to merge the list of overlays from the main nixCats example config
      # into any new overlays we provide here.
      dependencyOverlays = [ (utils.mergeOverlayLists nixCats.dependencyOverlays.${system} (/* import ./overlays inputs ++ */[
        # I also deleted the overlays directory and thus commented out the import call for it (but left the parenthesis for demonstration).
        (utils.standardPluginOverlay inputs)
      ])) ];
    in { inherit dependencyOverlays; })) dependencyOverlays;

    # NOTE:
    # mergeCatDefs is used to update categoryDefinitions from other nixCats flakes.
    # It will recurse until it hits something that is NOT a SET or IS a DERIVATION,
    # which is then REPLACED with the new value.
    categoryDefinitions = utils.mergeCatDefs nixCats.categoryDefinitions ({ pkgs, settings, categories, name, ... }@packageDef: {
      # Here we will use it to add some extra dependencies that will
      # be useful in the AppImage but werent needed in the original configuration.
      lspsAndRuntimeDeps = {
        # define a new appimage category which will be added alongside the others from the main nixCats example config
        appimage = with pkgs; [
          coreutils-full
          xclip
          wl-clipboard
          git
          nix # needed for nixd
          curl
          # We include these extra dependencies so that our AppImage will always have what it needs.
          # The appimage is not sandboxed from the path.
          # However it has its own internal /nix directory.

          # This means it cannot see packages that were installed
          # globally via nix specifically, but it will find things installed via other package managers.

          # since the main reason to use the AppImage is when you
          # cannot use nix at all, this ends up not being an issue.
        ];
      };
      # NOTE: since we have no luaPath here,
      # you can instead add plugins and configurations here
      # using the syntax from pkgs.wrapNeovimUnstable
      # We are using the luaPath from the main example nixCats config.
      # so any extra lua we wish to add to THAT config will be added via nix instead.
      # startupPlugins = {
      #   appimage = [
      #     {
      #       plugin = drv;
      #       type = "lua";
      #       config = "some lua config";
      #     }
      #   ];
      # };
      # NOTE: you could also do the following and source the current directory
      # ON TOP of the old one:
      # optionalLuaAdditions = {
      #   appimage = ''
      #     vim.opt.packpath:prepend("${./.}")
      #     vim.opt.runtimepath:prepend("${./.}")
      #     vim.opt.runtimepath:append("${./.}/after")
      #     dofile("${./.}/init.lua")
      #   '';
      # };
      # and yes you can do that in optionalLuaPreInit as well.

      # NOTE:
      # all the normal options here work.
      # see :h nixCats.flake.outputs.categories for the available sets
      # and see :h nixCats.flake.outputs.categoryDefinitions.scheme for extra information.

      # We are only using the lspsAndRuntimeDeps set in this example,
      # because that is all we needed to make the AppImage work.
      # In addition to the above syntax for including lua with plugins,
      # there is also optionalLuaAdditions and optionalLuaPreInit
      # as mechanisms to add lua that doesnt make sense to include in the plugin spec format shown above.
      # These are also covered in the mentioned help file.
    });

    packageDefinitions = {
      # NOTE:
      # we can use mergeCatDefs to update packageDefinitions as well!
      # for an example:
      # we pull in all the settings and categories from the nixCats example config
      # and then we also enable our new appimage category with the extra dependencies,
      # as well as change extraName and configDirName
      # then we put that in a new appCats package
      appCats = utils.mergeCatDefs nixCats.packageDefinitions.nixCats ({pkgs , ... }: {
        settings = {
          # You dont need to set these to be different, but I did.
          extraName = "appimagenvim"; # <-- so you can grep the store for this one
          configDirName = "appCats"; # <-- so that it doesnt share non-config directories in vim.fn.stdpath with other nvims
        };
        categories = {
          # include our new category
          appimage = true;
        };
      });
    };
    # and change the default package name to one that actually exists here
    defaultPackageName = "appCats";
    # ^ will also be the name of the module exported by the flake
  in

  forEachSystem (system: let
    # NOTE: since the luaPath is not hosted here, to include it from the main nixCats example config,
    # we use the exported keepLuaBuilder instead of a baseBuilder plus a luaPath.
    customPackager = nixCats.keepLuaBuilder {
      inherit nixpkgs system dependencyOverlays extra_pkg_config;
    } categoryDefinitions;
    nixCatsBuilder = customPackager packageDefinitions;
    pkgs = import nixpkgs { inherit system; };
  in
  {
    # NOTE: we add the appimage to our outputs that get wrapped by ${system}
    # and can build it with nix build .#app-images.${system}.default
    app-images = {
      default = nix-appimage.bundlers.${system}.default (nixCatsBuilder "appCats");
    };
    # adding nix-appimage to inputs, adding this output, and then adding any
    # other dependencies the errors ask for is all that is required to build an AppImage.
    # the rest of the help here is for the reconfiguration features of nixCats.

    inherit customPackager;
    packages = utils.mkPackages nixCatsBuilder packageDefinitions defaultPackageName;
    devShells = {
      default = pkgs.mkShell {
        name = defaultPackageName;
        packages = [ (nixCatsBuilder defaultPackageName) ];
        inputsFrom = [ ];
        shellHook = ''
        '';
      };
    };
  }) // {
    # NOTE: replace luaPath with keepLuaBuilder in this section,
    # because we do not have our own luaPath here.
    # These functions will accept either one.
    overlays = utils.makeOverlays nixCats.keepLuaBuilder {
      inherit nixpkgs dependencyOverlays extra_pkg_config;
    } categoryDefinitions packageDefinitions defaultPackageName;
    nixosModules.default = utils.mkNixosModules {
      inherit defaultPackageName dependencyOverlays
        categoryDefinitions packageDefinitions nixpkgs;
      inherit (nixCats) keepLuaBuilder;
    };
    homeModule = utils.mkHomeModules {
      inherit defaultPackageName dependencyOverlays
        categoryDefinitions packageDefinitions nixpkgs;
      inherit (nixCats) keepLuaBuilder;
    };
    inherit utils categoryDefinitions packageDefinitions dependencyOverlays;
    inherit (utils) templates baseBuilder;
    # and also re-export the keepLuaBuilder we used.
    inherit (nixCats) keepLuaBuilder;
    # because we export all the same things as the original,
    # we can repeat this reconfiguration process as many times as we like.
    # Chaining into infinity if we want.
    # I would not suggest doing it too many times though for sanity purposes...
    # You may just want to include a new package output in the original flake instead.
    # If you lose track of what categories you are inheriting,
    # the NixCats user command can display them within the editor!
  };
}
