# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
{
  isHomeManager
  , defaultPackageName ? null
  , moduleNamespace ? [ (if defaultPackageName != null then defaultPackageName else "nixCats") ]
  , luaPath ? ""
  , packageDefinitions ? {}
  , nclib
  , utils ? import ./.
}:
{ lib, ... }: let
  catDef = nclib.mkCatDefType lib.mkOptionType false;
  pkgDef = nclib.mkCatDefType lib.mkOptionType true;
in {

  config = lib.setAttrByPath moduleNamespace { inherit utils; };

  options = with lib; lib.setAttrByPath moduleNamespace ({

      nixpkgs_version = mkOption {
        default = null;
        type = types.nullOr (types.anything);
        description = ''
          a different nixpkgs import to use. By default will use the one from the flake, or system pkgs.
        '';
        example = ''
          nixpkgs_version = inputs.nixpkgs
        '';
      };

      addOverlays = mkOption {
        default = [];
        type = (types.listOf types.anything);
        description = ''
          A list of overlays to make available to any nixCats package from this module but not to your system.
          Will have access to system overlays regardless of this setting.
        '';
        example = ''
          addOverlays = [ (self: super: { nvimPlugins = { pluginDerivationName = pluginDerivation; }; }) ]
        '';
      };

      enable = mkOption {
        default = false;
        type = types.bool;
        description = "Enable the ${concatStringsSep "." moduleNamespace} module";
      };

      dontInstall = mkOption {
        default = false;
        type = types.bool;
        description = ''
          If true, do not output to packages list,
          output only to config.${concatStringsSep "." moduleNamespace}.out
        '';
      };

      luaPath = mkOption {
        default = luaPath;
        type = types.oneOf [ types.str types.path types.package ];
        description = ''
          The path to your nvim config directory in the store.
          In templates, this is "./."
        '';
        example = ''./nvim'';
      };

      packageNames = mkOption {
        default = if defaultPackageName != null && packageDefinitions ? "${defaultPackageName}" then [ defaultPackageName ] else [];
        type = (types.listOf types.str);
        description = ''A list of packages from packageDefinitions to include'';
        example = ''
          packageNames = [ "nixCats" ]
        '';
      };

      categoryDefinitions = {
        existing = mkOption {
          default = "replace";
          type = types.enum [ "replace" "merge" "discard" ];
          description = ''
            the merge strategy to use for categoryDefinitions inherited from the package this module was based on
            choose between "replace", "merge" or "discard"
            replace uses utils.mergeCatDefs
            merge uses utils.deepmergeCats
            discard does not inherit
            see :help nixCats.flake.outputs.exports for more info on the merge strategy options
          '';
        };
        replace = mkOption {
          default = null;
          type = types.nullOr (catDef "replace");
          description = ''
            see :help nixCats.flake.outputs.categories
            uses utils.mergeCatDefs to recursively update old categories with new values
            see :help nixCats.flake.outputs.exports for more info on the merge strategy options
          '';
          example = ''
            # see :help nixCats.flake.outputs.categories
            categoryDefinitions.replace = { pkgs, settings, categories, name, ... }@packageDef: { }
          '';
        };
        merge = mkOption {
          default = null;
          type = types.nullOr (catDef "merge");
          description = ''
            see :help nixCats.flake.outputs.categories
            uses utils.deepmergeCats to recursively update and merge category lists if duplicates are defined
            see :help nixCats.flake.outputs.exports for more info on the merge strategy options
          '';
          example = ''
            # see :help nixCats.flake.outputs.categories
            categoryDefinitions.merge = { pkgs, settings, categories, name, ... }@packageDef: { }
          '';
        };
      };

      packages = mkOption {
        default = null;
        type = with types; nullOr (attrsOf (catDef "replace"));
        visible = false;
      };

      packageDefinitions = {
        existing = mkOption {
          default = "replace";
          type = types.enum [ "replace" "merge" "discard" ];
          description = ''
            the merge strategy to use for packageDefinitions inherited from the package this module was based on
            choose between "replace", "merge" or "discard"
            replace uses utils.mergeCatDefs
            merge uses utils.deepmergeCats
            discard does not inherit
            see :help nixCats.flake.outputs.exports for more info on the merge strategy options
          '';
        };
        merge = mkOption {
          default = null;
          description = ''
            VERY IMPORTANT when setting aliases for each package,
            they must not be the same as ANY other neovim package for that user.
            It will cause a build conflict.

            You can have as many nixCats installed per user as you want,
            as long as you obey that rule.

            for information on the values you may return,
            see :help nixCats.flake.outputs.settings
            and :help nixCats.flake.outputs.categories
          '';
          type = with types; nullOr (attrsOf (pkgDef "merge"));
          example = ''
            packageDefinitions.merge = { 
              nixCats = { pkgs, ... }: {
                settings = {
                  wrapRc = true;
                  configDirName = "nixCats-nvim";
                  # nvimSRC = inputs.neovim;
                  aliases = [ "vim" "nixCats" ];
                };
                categories = {
                  generalBuildInputs = true;
                  markdown = true;
                  gitPlugins = true;
                  general = true;
                  custom = true;
                  neonixdev = true;
                  debug = false;
                  test = true;
                  lspDebugMode = false;
                  themer = true;
                  colorscheme = "onedark";
                };
              };
            }
          '';
        };
        replace = mkOption {
          default = null;
          description = ''
            VERY IMPORTANT when setting aliases for each package,
            they must not be the same as ANY other neovim package for that user.
            It will cause a build conflict.

            You can have as many nixCats installed per user as you want,
            as long as you obey that rule.

            for information on the values you may return,
            see :help nixCats.flake.outputs.settings
            and :help nixCats.flake.outputs.categories
          '';
          type = with types; nullOr (attrsOf (pkgDef "replace"));
          example = ''
            packageDefinitions.replace = { 
              nixCats = { pkgs, ... }: {
                settings = {
                  wrapRc = true;
                  configDirName = "nixCats-nvim";
                  # nvimSRC = inputs.neovim;
                  aliases = [ "vim" "nixCats" ];
                };
                categories = {
                  generalBuildInputs = true;
                  markdown = true;
                  gitPlugins = true;
                  general = true;
                  custom = true;
                  neonixdev = true;
                  debug = false;
                  test = true;
                  lspDebugMode = false;
                  themer = true;
                  colorscheme = "onedark";
                };
              };
            }
          '';
        };
      };

      utils = mkOption {
        type = types.attrsOf types.anything;
        readOnly = true;
        description = "[nixCats utils set](https://nixcats.org/nixCats_utils.html)";
      };

      out = {
        packages = mkOption {
          type = types.attrsOf types.package;
          readOnly = true;
          description = "Resulting customized neovim packages.";
        };
      } // (lib.optionalAttrs (! isHomeManager) {
        users = mkOption {
          description = ''
            Resulting customized neovim packages for users.
          '';
          readOnly = true;
          type = with types; attrsOf (submodule {
            options = {
              packages = mkOption {
                type = types.attrsOf types.package;
                readOnly = true;
                description = "Resulting customized neovim packages for this user";
              };
            };
          });
        };
      });

    } // (lib.optionalAttrs (! isHomeManager) {

      users = mkOption {
        default = {};
        description = ''
          same as system config but per user instead
        '';
        type = with types; attrsOf (submodule {
          options = {
            enable = mkOption {
              default = false;
              type = types.bool;
              description = "Enable the ${concatStringsSep "." moduleNamespace}.users module for a user";
            };

            dontInstall = mkOption {
              default = false;
              type = types.bool;
              description = ''
                If true, do not output to packages list,
                output only to config.${concatStringsSep "." moduleNamespace}.out.users
              '';
            };

            nixpkgs_version = mkOption {
              default = null;
              type = types.nullOr (types.anything);
              description = ''
                a different nixpkgs import to use for this users nvim.
                By default will use the one from ${concatStringsSep "." moduleNamespace}.nixpkgs_version, or flake, or system pkgs.
              '';
              example = ''
                nixpkgs_version = inputs.nixpkgs
              '';
            };

            addOverlays = mkOption {
              default = [];
              type = (types.listOf types.anything);
              description = ''
                A list of overlays to make available to
                this user's nixCats packages from this module but not to your system.
                Will have access to system overlays regardless of this setting.
                This per user version of addOverlays is merged with the value of ${concatStringsSep "." moduleNamespace}.addOverlays 
              '';
              example = ''
                addOverlays = [ (self: super: { nvimPlugins = { pluginDerivationName = pluginDerivation; }; }) ]
              '';
            };

            luaPath = mkOption {
              default = luaPath;
              type = types.oneOf [ types.str types.path types.package ];
              description = ''
                The path to your nvim config directory in the store.
                In templates, this is "./."
              '';
              example = ''./user_nvim'';
            };

            packageNames = mkOption {
              default = if defaultPackageName != null && packageDefinitions ? "${defaultPackageName}" then [ defaultPackageName ] else [];
              type = (types.listOf types.str);
              description = ''A list of packages from packageDefinitions to include'';
              example = ''
                packageNames = [ "nixCats" ]
              '';
            };

            categoryDefinitions = {
              existing = mkOption {
                default = "replace";
                type = types.enum [ "replace" "merge" "discard" ];
                description = ''
                  the merge strategy to use for categoryDefinitions inherited from the package this module was based on
                  choose between "replace", "merge" or "discard"
                  replace uses utils.mergeCatDefs
                  merge uses utils.deepmergeCats
                  discard does not inherit
                  see :help nixCats.flake.outputs.exports for more info on the merge strategy options
                '';
              };
              replace = mkOption {
                default = null;
                type = types.nullOr (catDef "replace");
                description = ''
                  see :help nixCats.flake.outputs.categories
                  uses utils.mergeCatDefs to recursively update old categories with new values
                  see :help nixCats.flake.outputs.exports for more info on the merge strategy options
                '';
                example = ''
                  categoryDefinitions.replace = { pkgs, settings, categories, name, extra, mkNvimPlugin, ... }@packageDef: { }
                '';
              };
              merge = mkOption {
                default = null;
                type = types.nullOr (catDef "merge");
                description = ''
                  see :help nixCats.flake.outputs.categories
                  uses utils.deepmergeCats to recursively update and merge category lists if duplicates are defined
                  see :help nixCats.flake.outputs.exports for more info on the merge strategy options
                '';
                example = ''
                  categoryDefinitions.merge = { pkgs, settings, categories, name, extra, mkNvimPlugin, ... }@packageDef: { }
                '';
              };
            };

            packages = mkOption {
              default = null;
              type = with types; nullOr (attrsOf (catDef "replace"));
              visible = false;
            };

            packageDefinitions = {
              existing = mkOption {
                default = "replace";
                type = types.enum [ "replace" "merge" "discard" ];
                description = ''
                  the merge strategy to use for categoryDefinitions inherited from the package this module was based on
                  choose between "replace", "merge" or "discard"
                  replace uses utils.mergeCatDefs
                  merge uses utils.deepmergeCats
                  discard does not inherit
                  see :help nixCats.flake.outputs.exports for more info on the merge strategy options
                '';
              };
              merge = mkOption {
                default = null;
                description = ''
                  VERY IMPORTANT when setting aliases for each package,
                  they must not be the same as ANY other neovim package for that user.
                  It will cause a build conflict.

                  You can have as many nixCats installed per user as you want,
                  as long as you obey that rule.

                  for information on the values you may return,
                  see :help nixCats.flake.outputs.settings
                  and :help nixCats.flake.outputs.categories
                '';
                type = with types; nullOr (attrsOf (pkgDef "merge"));
                example = ''
                  nixCats.users.<USER>.packageDefinitions.merge = { 
                    nixCats = { pkgs, ... }: {
                      settings = {
                        wrapRc = true;
                        configDirName = "nixCats-nvim";
                        # nvimSRC = inputs.neovim;
                        aliases = [ "vim" "nixCats" ];
                      };
                      categories = {
                        generalBuildInputs = true;
                        markdown = true;
                        gitPlugins = true;
                        general = true;
                        custom = true;
                        neonixdev = true;
                        debug = false;
                        test = true;
                        lspDebugMode = false;
                        themer = true;
                        colorscheme = "onedark";
                      };
                    };
                  }
                '';
              };
              replace = mkOption {
                default = null;
                description = ''
                  VERY IMPORTANT when setting aliases for each package,
                  they must not be the same as ANY other neovim package for that user.
                  It will cause a build conflict.

                  You can have as many nixCats installed per user as you want,
                  as long as you obey that rule.

                  for information on the values you may return,
                  see :help nixCats.flake.outputs.settings
                  and :help nixCats.flake.outputs.categories
                '';
                type = with types; nullOr (attrsOf (pkgDef "replace"));
                example = ''
                  nixCats.users.<USER>.packageDefinitions.replace = { 
                    nixCats = { pkgs, ... }: {
                      settings = {
                        wrapRc = true;
                        configDirName = "nixCats-nvim";
                        # nvimSRC = inputs.neovim;
                        aliases = [ "vim" "nixCats" ];
                      };
                      categories = {
                        generalBuildInputs = true;
                        markdown = true;
                        gitPlugins = true;
                        general = true;
                        custom = true;
                        neonixdev = true;
                        debug = false;
                        test = true;
                        lspDebugMode = false;
                        themer = true;
                        colorscheme = "onedark";
                      };
                    };
                  }
                '';
              };
            };

          };
        });
      };
    }));

}
