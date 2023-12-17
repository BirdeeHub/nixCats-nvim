# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).


# THIS IS NOT A COMPLETE NIXOS CONFIG FILE!!!
# THIS IS A TEMPLATE FOR JUST HOW TO IMPORT NIXCATS BASED CONFIGS INTO IT

# THIS IS NOT A COMPLETE NIXOS CONFIG FILE!!!
# THIS IS A TEMPLATE FOR JUST HOW TO IMPORT NIXCATS BASED CONFIGS INTO IT

# IT DOES NOT IMPORT THE RESULTS OF THE HARDWARE SCAN
# IT DOES NOT EVEN HAVE A stateVersion VALUE.
# It will not build.

# However, if you add the module like shown in flake.nix,
# these are SOME of the options that will be made available to you.
# For other nixCats options not included in this template
# see :help nixCats.flake.outputs.exports.mkNixosModules

{ config, pkgs, self, inputs, ... }: {

  # this value, nixCats is the defaultPackageName you pass to mkNixosModules
  # it will be the namespace for your options.
  nixCats = {
    # these are some of the options. For the rest see
    # :help nixCats.flake.outputs.utils.mkNixosModules
    # you do not need to use every option here, anything you do not define
    # will be pulled from the flake instead.
    enable = true;
    packageName = "myNixModuleNvim";

    # say for example, in your nix system config,
    # you wanted your lua in myNeovimConfig directory at root level
    # and then activate nixCats and download stuff from here,
    luaPath = "${self}/myNeovimConfig";
    # you could also import it from the flake though,
    # which we do for user config after this config for root
    # I HAVE NOT CREATED THIS DIRECTORY FOR YOU, thus this will find no config
    # make your own directory if you want to put it there.

    # packageDef is your settings and categories for this package.
    # categoryDefinitions.replace will replace the whole categoryDefinitions with a new one
    categoryDefinitions.replace = (packageDef: {
      propagatedBuildInputs = {
        # add to general or create a new list called whatever
        general = [];
      };
      lspsAndRuntimeDeps = {
        general = [];
      };
      startupPlugins = {
        general = [];
        # themer = with pkgs; [
        #   # you can even make subcategories based on categories and settings sets!
        #   (builtins.getAttr packageDef.categories.colorscheme {
        #       "onedark" = onedark-vim;
        #       "catppuccin" = catppuccin-nvim;
        #       "catppuccin-mocha" = catppuccin-nvim;
        #       "tokyonight" = tokyonight-nvim;
        #       "tokyonight-day" = tokyonight-nvim;
        #     }
        #   )
        # ];
      };
      optionalPlugins = {
        general = [];
      };
      environmentVariables = {
        test = {
          CATTESTVAR = "It worked!";
        };
      };
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
    });
    settings = {
      # This folder is ran from the store
      # if wrapRc = true;
      # since this is in our main config folder,
      # rather than in ~/.config/configDirName
      # this should always be true.
      wrapRc = true;
      # It will look for configDirName in .local, etc
      # this name does not need to match packageName
      configDirName = "myNixModuleNvim";
      viAlias = false;
      vimAlias = true;
    };
    categories = {
      # themer = true;
      # colorscheme = catppuccin;
      general = true;
      test = true;
    };



    # and other options for the user birdee
    # this will be nixCats but with eyeliner-nvim and tokyonight
    users.birdee = {
      enable = true;
      packageName = "nixCats";
      # we are going to add a category, and a plugin,
      # from only within nix to an existing config,
      # just to show we can.
      # If you wanted to add lua and a plugin for only 1 system
      # you could import your regular flake you made and add the plugin.
      # this would be instead of making a separate package in the flake
      # that is only used on the one system.

      # this one imports the lua from nixCats and adds the plugin.
      # categoryDefinitions.merge will recursively update them
      # such that you can redefine only particular categories.
      # or add new ones, as we do here.

      # For environmentVariables, it will update them individually rather than by category.
      # this is because each category of environmentVariables is a set rather than a list.
      categoryDefinitions.merge = (packageDef: {
        startupPlugins = {
          eyeliner = with pkgs.vimPlugins; [
            eyeliner-nvim
          ];
        };
        optionalLuaAdditions = ''
          if nixCats('eyeliner') then
            require'eyeliner'.setup {
              highlight_on_key = true,
              dim = true
            }
          end
        '';
      });
      # here we get the previous categories for nixCats package, and update it with
      # our new category with a new plugin. and also a new colorscheme.
      categories = inputs.nixCats.packageDefinitions.${pkgs.system}.nixCats.categories
      // {
        eyeliner = true;
        colorscheme = "tokyonight";
      };
    };
  };


}
