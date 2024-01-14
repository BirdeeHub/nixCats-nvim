{ config, pkgs, lib, inputs, ... }: let
  utils = inputs.nixCats.utils;
  # the options for this are defined at the end of the file,
  # and will be how to include this template module in your system configuration.
  cfg = config.myNixCats;
in {
  imports = [
    inputs.nixCats.nixosModules.${pkgs.system}.default
  ];
  config = {
    # this value, nixCats is the defaultPackageName you pass to mkNixosModules
    # it will be the namespace for your options.
    nixCats = lib.mkIf cfg.enable {
      # these are some of the options. For the rest see
      # :help nixCats.flake.outputs.utils.mkNixosModules
      # you do not need to use every option here, anything you do not define
      # will be pulled from the flake instead.
      enable = true;
      # this will add the overlays from ./overlays and also,
      # add any plugins in inputs named "plugins-pluginName" to pkgs.neovimPlugins
      addOverlays = (import ./overlays inputs) ++ [
        (utils.standardPluginOverlay inputs)
      ];
      packageName = "myNixModuleNvim";

      luaPath = "${./.}";
      # you could also import lua from the flake though,
      # which we do for user config after this config for root

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

      settings = if cfg.settings != null then cfg.settings
      else {
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

      categories = if cfg.categories != null then cfg.categories
      else {
        # themer = true;
        # colorscheme = catppuccin;
        general = true;
        test = true;
      };

      extraPackageDefs = {
        xtravim = {
          settings = {
            wrapRc = true;
            configDirName = "nixCats-nvim";
            customAliases = [ "xtravim" ];
            # nvimSRC = inputs.neovim;
          };
          categories = {
            general = true;
            test = true;
          };
        };
      } // (if cfg.extraPackageDefs != null
        then cfg.extraPackageDefs else {});



      # and other options for the user REPLACE_ME
      # It is highly suggested to use home manager instead of these options
      users.REPLACE_ME = {
        enable = true;
        packageName = "nixCats";
        # this will be the base nixCats but with eyeliner-nvim and tokyonight
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
        # enable the category
        categories = inputs.nixCats.packageDefinitions.${pkgs.system}.nixCats.categories
        // {
          eyeliner = true;
          colorscheme = "tokyonight";
        };
      };
    };
  };

  # this module will export these options for your main configuration file.
  # you will set up the configuration here, and you may tweak it there with these
  options = with lib; {
    myNixCats = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = "Enable myNixModuleNvim";
      };
      settings = mkOption {
        default = null;
        type = types.nullOr (types.attrsOf types.anything);
        description = "You may optionally provide a new category set for packageDefinitions";
        example = ''
          {
            wrapRc = true;
            configDirName = "myNixModuleNvim";
            # nvimSRC = inputs.neovim;
          }
        '';
      };
      categories = mkOption {
        default = null;
        type = types.nullOr (types.attrsOf types.anything);
        description = "You may optionally provide a new category set for packageDefinitions";
        example = ''
          {
            general = true;
            test = true;
          }
        '';
      };
      extraPackageDefs = mkOption {
        default = null;
        description = ''
          Same as nixCats settings and categories except, you are in charge of making sure
          that the aliases don't collide with any other packageDefinitions
          Will build all included.
        '';
        type = with types; nullOr (attrsOf (submodule {
          options = {
            settings = mkOption {
              default = {};
              type = (types.attrsOf types.anything);
              description = ''
                Same as nixCats.settings except, you are in charge of making sure the aliases don't collide with any other packageDefinitions
              '';
              example = ''
                {
                  wrapRc = true;
                  configDirName = "nixCats-nvim";
                  customAliases = [ "xtravim" ];
                  # nvimSRC = inputs.neovim;
                }
              '';
            };
            categories = mkOption {
              default = {};
              type = (types.attrsOf types.anything);
              description = "same as nixCats.categories, but for the extra package";
              example = ''
                {
                  general = true;
                  test = true;
                }
              '';
            };
          };
        }));
      };
    };
  };
}