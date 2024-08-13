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
      # these are some of the options. For the rest see
      # :help nixCats.flake.outputs.utils.mkNixosModules
      # you do not need to use every option here, anything you do not define
      # will be pulled from the flake instead.
      enable = true;
      # this will add the overlays from ./overlays and also,
      # add any plugins in inputs named "plugins-pluginName" to pkgs.neovimPlugins
      # It will not apply to overall system, just nixCats.
      addOverlays = /* (import ./overlays inputs) ++ */ [
        (utils.standardPluginOverlay inputs)
      ];
      packageNames = [ "myNixModuleNvim" ];

      luaPath = "${./.}";
      # you could also import lua from the flake though,
      # which we do for user config after this config for root

      # packageDef is your settings and categories for this package.
      # categoryDefinitions.replace will replace the whole categoryDefinitions with a new one
      categoryDefinitions.replace = ({ pkgs, settings, categories, name, ... }@packageDef: {
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
      packages = {
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



      users.REPLACE_ME = {
        enable = true;
        packageNames = [ "REPLACE_MEs_VIM" ];
        # this will be the base nixCats but with eyeliner-nvim and tokyonight
        # this one imports the lua from nixCats and adds the plugin.
        # categoryDefinitions.merge will recursively update them
        # such that you can redefine only particular categories.
        # or add new ones, as we do here.
        # For environmentVariables, it will update them individually rather than by category.
        # this is because each category of environmentVariables is a set rather than a list.
        categoryDefinitions.merge = ({ pkgs, settings, categories, name, ... }@packageDef: {
          startupPlugins = {
            eyeliner = with pkgs.vimPlugins; [
              eyeliner-nvim
            ];
          };
          optionalLuaAdditions = {
            eyeliner = ''
              if nixCats('eyeliner') then
                require'eyeliner'.setup {
                  highlight_on_key = true,
                  dim = true
                }
              end
            '';
          };
        });
        packages = {
          REPLACE_MEs_VIM = {pkgs, ...}: {
            settings = {
              # will check for config in the store rather than .config
              wrapRc = true;
              configDirName = "nixCats-nvim";
              aliases = [ "REPLACE_MY_VIM" ];
              # neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
            };
            # see :help nixCats.flake.outputs.packageDefinitions
            categories = {
              generalBuildInputs = true;
              markdown = true;
              general.vimPlugins = true;
              general.gitPlugins = true;
              custom = true;
              neonixdev = true;
              test = {
                subtest1 = true;
              };
              debug = false;
              # this does not have an associated category of plugins, 
              # but lua can still check for it
              lspDebugMode = false;
              # by default, we dont want lazy.nvim
              # we could omit this for the same effect
              lazy = false;
              eyeliner = true;
              # you could also pass something else:
              themer = true;
              colorscheme = "tokyonight";
              theBestCat = "says meow!!";
              theWorstCat = {
                thing'1 = [ "MEOW" "HISSS" ];
                thing2 = [
                  {
                    thing3 = [ "give" "treat" ];
                  }
                  "I LOVE KEYBOARDS"
                ];
                thing4 = "couch is for scratching";
              };
              # see :help nixCats
            };
          };
        };
      };
    };
  };
}
