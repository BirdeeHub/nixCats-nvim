# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
{
  inputs
  , otherOverlays
  , luaPath ? ""
  , keepLuaBuilder ? null
  , categoryDefinitions
  , packageDefinitions
  , defaultPackageName
  , ...
}: utils:

{ config, pkgs, lib, ... }@misc: {

  options = with lib; {

    ${defaultPackageName} = {

      enable = mkOption {
        default = false;
        type = types.bool;
        description = "Enable ${defaultPackageName}";
      };
      packageName = mkOption {
        default = "${defaultPackageName}";
        type = types.str;
        description = ''
          The name of the package to be built from packageDefinitions.
          If using BOTH custom settings and categories, this can be arbitrary
        '';
        example = ''${defaultPackageName}'';
      };
      luaPath = mkOption {
        default = luaPath;
        type = types.str;
        description = ''
          The path to your nvim config directory in the store.
          In the base nixCats flake, this is "''${self}".
        '';
        example = ''"''${self}/systemLuaConfig"'';
      };
      settings = mkOption {
        default = packageDefinitions.${config.${defaultPackageName}.packageName}.settings or {};
        type = (types.attrsOf types.anything);
        description = "You may optionally provide your own settings set for packageDefinitions";
        example = ''
          {
            wrapRc = true;
            configDirName = "nixCats-nvim";
            viAlias = false;
            vimAlias = true;
            # nvimSRC = inputs.neovim;
          }
        '';
      };
      categories = mkOption {
        default = packageDefinitions.${config.${defaultPackageName}.packageName}.categories or {};
        type = (types.attrsOf types.anything);
        description = "You may optionally provide your own category set for packageDefinitions";
        example = ''
          {
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
          }
        '';
      };
      addOverlays = mkOption {
        default = [];
        type = (types.listOf types.anything);
        description = ''A list of overlays to make available to categoryDefinitions (and pkgs in general)'';
        example = ''
          [ (self: super: { vimPlugins = { pluginDerivationName = pluginDerivation; }; }) ]
        '';
      };
      addInputs = mkOption {
        default = {};
        type = (types.attrsOf types.anything);
        description = ''
          A set of flake inputs to make available to
          standardPluginOverlay and categoryDefinitions
        '';
        example = ''the inputs set of a flake'';
      };
      categoryDefinitions = {
        replace = mkOption {
          default = null;
          type = types.nullOr (types.functionTo (types.attrsOf types.anything));
          description = ''
            Takes a function that receives the package definition set of this package
            and returns a set of categoryDefinitions,
            just like :help nixCats.flake.outputs.categories
            Will replace the categoryDefinitions of the flake with this value.
          '';
          example = ''
            # see :help nixCats.flake.outputs.categories
            categoryDefinitions = packageDef: { }
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
            categoryDefinitions = packageDef: { }
          '';
        };
      };

      users = mkOption {
        default = {};
        description = "same as system config but per user instead";
        type = with types; attrsOf (submodule {
          options = {
            enable = mkOption {
              default = false;
              type = types.bool;
              description = "Enable ${defaultPackageName}";
            };
            packageName = mkOption {
              default = "${defaultPackageName}";
              type = types.str;
              description = ''
                The name of the package to be built from packageDefinitions. If using BOTH custom settings and categories, this can be arbitrary
              '';
              example = ''${defaultPackageName}'';
            };
            luaPath = mkOption {
              default = luaPath;
              type = types.str;
              description = ''
                The path to your nvim config directory in the store. In the base nixCats flake, this is "''${self}".
              '';
              example = ''"''${self}/systemNvimConfig"'';
            };
            settings = mkOption {
              default = null;
              type = types.nullOr (types.attrsOf types.anything);
              description = "You may optionally provide your own settings set";
              example = ''
                {
                  wrapRc = true;
                  configDirName = "nixCats-nvim";
                  viAlias = false;
                  vimAlias = true;
                  # nvimSRC = inputs.neovim;
                }
              '';
            };
            categories = mkOption {
              default = null;
              type = types.nullOr (types.attrsOf types.anything);
              description = "You may optionally provide your own category set";
              example = ''
                {
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
                }
              '';
            };
            addOverlays = mkOption {
              default = [];
              type = (types.listOf types.anything);
              description = ''A list of overlays to make available to categoryDefinitions (and pkgs in general)'';
              example = ''
                [ (self: super: { vimPlugins = { pluginDerivationName = pluginDerivation; }; }) ]
              '';
            };
            addInputs = mkOption {
              default = {};
              type = (types.attrsOf types.anything);
              description = ''A set of flake inputs to make available to standardPluginOverlay and categoryDefinitions'';
              example = ''the inputs set of a flake'';
            };
            categoryDefinitions = {
              replace = mkOption {
                default = null;
                type = types.nullOr (types.functionTo (types.attrsOf types.anything));
                description = ''
                  Takes a function that receives the package definition set of this package
                  and returns a set of categoryDefinitions,
                  just like :help nixCats.flake.outputs.categories
                  Will replace the categoryDefinitions of the flake with this value.
                '';
                example = ''
                  # see :help nixCats.flake.outputs.categories
                  categoryDefinitions = packageDef: { }
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
                  categoryDefinitions = packageDef: { }
                '';
              };
            };
          };
        });
      };
    };

  };

  config = let
    newUserPackageDefinitions = builtins.mapAttrs ( uname: _: let
      user_options_set = config.${defaultPackageName}.users.${uname};
      newCategoryDefinitions = if user_options_set.categoryDefinitions.replace != null
        then user_options_set.categoryDefinitions.replace
        else (
          if user_options_set.categoryDefinitions.merge != null then
          (utils.mergeCatDefs categoryDefinitions user_options_set.categoryDefinitions.merge)
          else categoryDefinitions
        );
      newUserPackageDefinition = {
        ${user_options_set.packageName} = {
          settings = if user_options_set.settings != null 
              then user_options_set.settings
              else packageDefinitions.${user_options_set.packageName}.settings;
          categories = if user_options_set.categories != null
              then user_options_set.categories
              else packageDefinitions.${user_options_set.packageName}.categories;
        };
      };
      in {
        packages = lib.mkIf user_options_set.enable
          [ (
              (
                if user_options_set.luaPath != "" then (utils.baseBuilder user_options_set.luaPath)
                else (
                  if keepLuaBuilder != null then 
                  keepLuaBuilder else 
                  builtins.throw "no lua or keepLua builder supplied to mkNixosModules"
                )
              )
              pkgs newCategoryDefinitions
              newUserPackageDefinition user_options_set.packageName
            )
          ];
      }
    ) config.${defaultPackageName}.users;

    options_set = config.${defaultPackageName};
    newOtherOverlays = [ (utils.mergeOverlayLists otherOverlays options_set.addOverlays) ];
    newCategoryDefinitions = if options_set.categoryDefinitions.replace != null
      then options_set.categoryDefinitions.replace
      else (
        if options_set.categoryDefinitions.merge != null then
        (utils.mergeCatDefs categoryDefinitions options_set.categoryDefinitions.merge)
        else categoryDefinitions
      );
    newSystemPackageDefinition = {
      ${options_set.packageName} = {
        settings = options_set.settings;
        categories = options_set.categories;
      };
    };
  in
  {
    nixpkgs.overlays = newOtherOverlays
      ++ [ (utils.standardPluginOverlay (inputs // options_set.addInputs)) ];
    users.users = newUserPackageDefinitions;
    environment.systemPackages = lib.mkIf options_set.enable
      [ (
          (
            if options_set.luaPath != "" then (utils.baseBuilder options_set.luaPath)
            else (
              if keepLuaBuilder != null then 
              keepLuaBuilder else 
              builtins.throw "no lua or keepLua builder supplied to mkNixosModules"
            )
          ) pkgs newCategoryDefinitions newSystemPackageDefinition options_set.packageName
        )
      ];
  };

}

