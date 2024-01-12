
# THIS IS NOT A COMPLETE HOME-MANAGER CONFIG FILE!!!
# THIS IS A TEMPLATE FOR JUST HOW TO IMPORT NIXCATS BASED CONFIGS INTO IT

# THIS IS NOT A COMPLETE HOME-MANAGER CONFIG FILE!!!
# THIS IS A TEMPLATE FOR JUST HOW TO IMPORT NIXCATS BASED CONFIGS INTO IT

# IT DOES NOT SPECIFY A USERNAME, OR A HOME DIRECTORY
# IT DOES NOT EVEN ALLOW HOME MANAGER TO INSTALL ITSELF.
# IT DOES NOT EVEN HAVE A stateVersion VALUE.
# It will not build.

# However, if you add the module like shown in flake.nix,
# these are SOME of the options that will be made available to you.

# for the rest, see :help nixCats.flake.outputs.exports.mkHomeModules

{ config, pkgs, self, inputs, ...  }:
{
  # this value, nixCats is the defaultPackageName you pass to mkNixosModules
  # it will be the namespace for your options.
  nixCats = {
    # these are some of the options. For the rest see
    # :help nixCats.flake.outputs.utils.mkNixosModules
    # you do not need to use every option here, anything you do not define
    # will be pulled from the flake instead.
    enable = true;
    packageName = "myHomeModuleNvim";

    luaPath = "${./.}";
    # you could also import the lua from the flake though,
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
      configDirName = "myHomeModuleNvim";
      viAlias = false;
      vimAlias = true;
    };
    categories = {
      # themer = true;
      # colorscheme = catppuccin;
      general = true;
      test = true;
    };
  };

}
