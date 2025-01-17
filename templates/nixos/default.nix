{ config, lib, inputs, ... }: let
  utils = inputs.nixCats.utils;
in {
  imports = [
    inputs.nixCats.nixosModules.default
  ];
  config = {
    # this value, nixCats is the defaultPackageName you pass to mkNixosModules
    # it will be the namespace for your options.
    nixCats = {
      enable = true;
      nixpkgs_version = inputs.nixpkgs;
      # this will add the overlays from ./overlays and also,
      # add any plugins in inputs named "plugins-pluginName" to pkgs.neovimPlugins
      # It will not apply to overall system, just nixCats.
      addOverlays = /* (import ./overlays inputs) ++ */ [
        (utils.standardPluginOverlay inputs)
      ];
      # see the packageDefinitions below.
      # This says which of those to install.
      packageNames = [ "myNixModuleNvim" ];

      luaPath = "${./.}";

      # the .replace vs .merge options are for modules based on existing configurations,
      # they refer to how multiple categoryDefinitions get merged together by the module.
      # for useage of this section, refer to :h nixCats.flake.outputs.categories
      categoryDefinitions.replace = ({ pkgs, settings, categories, extra, name, mkNvimPlugin, ... }@packageDef: {
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
      });

      # see :help nixCats.flake.outputs.packageDefinitions
      packageDefinitions.replace = {
        # These are the names of your packages
        # you can include as many as you wish.
        myNixModuleNvim = {pkgs , ... }: {
          # they contain a settings set defined above
          # see :help nixCats.flake.outputs.settings
          settings = {
            wrapRc = true;
            # IMPORTANT:
            # your alias may not conflict with your other packages.
            aliases = [ "vim" "systemVim" ];
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



      # you can do it per user as well
      users.REPLACE_ME = {
        enable = true;
        packageNames = [ "REPLACE_MEs_VIM" ];
        categoryDefinitions.replace = ({ pkgs, settings, categories, extra, name, mkNvimPlugin, ... }@packageDef: {
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
        });
        packageDefinitions.replace = {
          REPLACE_MEs_VIM = {pkgs, ...}: {
            settings = {
              wrapRc = true;
              # IMPORTANT:
              # your alias may not conflict with your other packages.
              aliases = [ "vim" "systemVim" ];
              # neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
            };
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
      };
    };
  };
}
