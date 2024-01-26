# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
{
  oldDependencyOverlays
  , luaPath ? ""
  , keepLuaBuilder ? null
  , categoryDefinitions
  , packageDefinitions
  , defaultPackageName
  , utils
  , nixpkgs
  , ...
}:

{ config, pkgs, lib, ... }@misc: {

  options = with lib; {

    ${defaultPackageName} = {

      nixpkgs_version = mkOption {
        default = null;
        type = types.nullOr (types.anything);
        description = ''
          a different nixpkgs import to use. By default will use the one from the flake.
        '';
        example = ''
          nixpkgs_version = inputs.nixpkgs
        '';
      };

      addOverlays = mkOption {
        default = [];
        type = (types.listOf types.anything);
        description = ''
          A list of overlays to make available to nixCats but not to your system.
          Will have access to system overlays regardless of this setting.
        '';
        example = (lib.literalExpression ''
          addOverlays = [ (self: super: { neovimPlugins = { pluginDerivationName = pluginDerivation; }; }) ]
        '');
      };

      enable = mkOption {
        default = false;
        type = types.bool;
        description = "Enable ${defaultPackageName}";
      };

      luaPath = mkOption {
        default = luaPath;
        type = types.str;
        description = (lib.literalExpression ''
          The path to your nvim config directory in the store.
          In the base nixCats flake, this is "${./.}".
        '');
        example = (lib.literalExpression "${./.}/userLuaConfig");
      };

      packageNames = mkOption {
        default = [ "${defaultPackageName}" ];
        type = (types.listOf types.str);
        description = ''A list of packages from packageDefinitions to include'';
        example = ''
          packageNames = [ "nixCats" ]
        '';
      };

      categoryDefinitions = {
        replace = mkOption {
          default = null;
          type = types.nullOr (types.functionTo (types.attrsOf types.anything));
          description = (lib.literalExpression ''
            Takes a function that receives the package definition set of this package
            and returns a set of categoryDefinitions,
            just like :help nixCats.flake.outputs.categories
            you should use ${pkgs.system} provided in the packageDef set
            to access system specific items.
            Will replace the categoryDefinitions of the flake with this value.
          '');
          example = ''
            # see :help nixCats.flake.outputs.categories
            categoryDefinitions.replace = { pkgs, settings, categories, name, ... }@packageDef: { }
          '';
        };
        merge = mkOption {
          default = null;
          type = types.nullOr (types.functionTo (types.attrsOf types.anything));
          description = ''
            Takes a function that receives the package definition set of this package
            and returns a set of categoryDefinitions,
            just like :help nixCats.flake.outputs.categories
            Will merge the categoryDefinitions of the flake with this value,
            recursively updating all non-attrset values,
            such as replacing old category lists with ones defined here.
          '';
          example = ''
            # see :help nixCats.flake.outputs.categories
            categoryDefinitions.merge = { pkgs, settings, categories, name, ... }@packageDef: { }
          '';
        };
      };

      packages = mkOption {
        default = null;
        description = ''
          VERY IMPORTANT when setting aliases for each package,
          they must not be the same as ANY other neovim package for that user.
          YOU MAY NOT ALIAS TO NVIM ITSELF
          It will cause a build conflict.

          You also cannot install nixCats via multiple sources per user.
          i.e. if you have it installed as a package, you cannot install it
          as a module.

          However, you can have as many nixCats as you want,
          as long as you obey those rules.
          This is a big step up from only being able to have 1 neovim
          at all per user, so excuse me for the inconvenience. This may be fixed someday.

          for information on the values you may return,
          see :help nixCats.flake.outputs.settings
          and :help nixCats.flake.outputs.categories
          https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix/nixCatsHelp/nixCatsFlake.txt
        '';
        type = with types; nullOr (attrsOf (functionTo (attrsOf anything)));
        example = ''
          nixCats.packages = { 
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

      users = mkOption {
        default = {};
        description = ''
          same as system config but per user instead
          and without addOverlays or nixpkgs_version
        '';
        type = with types; attrsOf (submodule {
          options = {
            enable = mkOption {
              default = false;
              type = types.bool;
              description = "Enable ${defaultPackageName}";
            };

            luaPath = mkOption {
              default = luaPath;
              type = types.str;
              description = ''
                The path to your nvim config directory in the store.
                In the base nixCats flake, this is "''${./.}".
              '';
              example = ''"''${./.}/userLuaConfig"'';
            };

            packageNames = mkOption {
              default = [ "${defaultPackageName}" ];
              type = (types.listOf types.str);
              description = ''A list of packages from packageDefinitions to include'';
              example = ''
                [ "nixCats" ]
              '';
            };

            categoryDefinitions = {
              replace = mkOption {
                default = null;
                type = types.nullOr (types.functionTo (types.attrsOf types.anything));
                description = ''
                  Takes a function that receives the package definition set of this package
                  and returns a set of categoryDefinitions,
                  just like :help nixCats.flake.outputs.categories
                  you should use ''${pkgs.system} provided in the packageDef set
                  to access system specific items.
                  Will replace the categoryDefinitions of the flake with this value.
                '';
                example = ''
                  # see :help nixCats.flake.outputs.categories
                  categoryDefinitions = { pkgs, settings, categories, name, ... }@packageDef: { }
                '';
              };
              merge = mkOption {
                default = null;
                type = types.nullOr (types.functionTo (types.attrsOf types.anything));
                description = ''
                  Takes a function that receives the package definition set of this package
                  and returns a set of categoryDefinitions,
                  just like :help nixCats.flake.outputs.categories
                  Will merge the categoryDefinitions of the flake with this value,
                  recursively updating all non-attrset values,
                  such as replacing old category lists with ones defined here.
                '';
                example = ''
                  # see :help nixCats.flake.outputs.categories
                  categoryDefinitions = { pkgs, settings, categories, name, ... }@packageDef: { }
                '';
              };
            };

            packages = mkOption {
              default = null;
              description = ''
                VERY IMPORTANT when setting aliases for each package,
                they must not be the same as ANY other neovim package for that user.
                YOU MAY NOT ALIAS TO NVIM ITSELF
                It will cause a build conflict.

                You also cannot install nixCats via multiple sources per user.
                i.e. if you have it installed as a package, you cannot install it
                as a module.

                However, you can have as many nixCats as you want,
                as long as you obey those rules.
                This is a big step up from only being able to have 1 neovim
                at all per user, so excuse me for the inconvenience. This may be fixed someday.

                for information on the values you may return,
                see :help nixCats.flake.outputs.settings
                and :help nixCats.flake.outputs.categories
                https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix/nixCatsHelp/nixCatsFlake.txt
              '';
              type = with types; nullOr (attrsOf (functionTo (attrsOf anything)));
              example = ''
                nixCats.packages = { 
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
        });
      };
    };

  };

  config = let
    dependencyOverlays = oldDependencyOverlays // {
      ${pkgs.system} = [
        (utils.mergeOverlayLists
          [ (utils.mergeOverlayLists
            oldDependencyOverlays.${pkgs.system} options_set.addOverlays
          ) ] pkgs.overlays)
      ];
    };

    mapToPackages = options_set: dependencyOverlays: (let
      newCategoryDefinitions = if options_set.categoryDefinitions.replace != null
        then options_set.categoryDefinitions.replace
        else (
          if options_set.categoryDefinitions.merge != null
            then (utils.mergeCatDefs categoryDefinitions options_set.categoryDefinitions.merge)
            else categoryDefinitions);

      pkgDefs = if (options_set.packages != null)
        then packageDefinitions // options_set.packages else packageDefinitions;

      newLuaBuilder = (if options_set.luaPath != "" then (utils.baseBuilder options_set.luaPath)
        else 
          (if keepLuaBuilder != null
            then keepLuaBuilder else 
            builtins.throw "no lua or keepLua builder supplied to mkNixosModules"));

      newNixpkgs = if config.${defaultPackageName}.nixpkgs_version != null
        then config.${defaultPackageName}.nixpkgs_version else nixpkgs;

    in (builtins.map (catName:
      newLuaBuilder {
          pkgs =  import newNixpkgs {
            inherit (pkgs) config system;
            overlays = dependencyOverlays.${pkgs.system};
          };
          inherit dependencyOverlays;
        } newCategoryDefinitions pkgDefs catName) options_set.packageNames)
    );

    newUserPackageDefinitions = builtins.mapAttrs ( uname: _: let
      user_options_set = config.${defaultPackageName}.users.${uname};
      in {
        packages = lib.mkIf options_set.enable (mapToPackages user_options_set dependencyOverlays);
      }
    ) config.${defaultPackageName}.users;

    options_set = config.${defaultPackageName};
  in
  {
    users.users = newUserPackageDefinitions;
    environment.systemPackages = lib.mkIf options_set.enable (mapToPackages options_set dependencyOverlays);
  };
}

