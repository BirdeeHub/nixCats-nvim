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
          In the base nixCats flake, this is "''${./.}".
        '';
        example = ''"''${./.}/systemLuaConfig"'';
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
        extraPackageDefs = mkOption {
          default = {};
          description = ''
            Same as nixCats settings and categories except, you are in charge of making sure
            that the aliases don't collide with any other packageDefinitions
          '';
          type = with types; attrsOf (submodule {
            options = {
              settings = mkOption {
                default = packageDefinitions.${config.${defaultPackageName}.packageName}.settings or {};
                type = (types.attrsOf types.anything);
                description = ''
                  Same as nixCats.settings except, you are in charge of making sure the aliases don't collide with any other packageDefinitions
                  Will build all included.
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
                default = packageDefinitions.${config.${defaultPackageName}.packageName}.categories or {};
                type = (types.attrsOf types.anything);
                description = "same as nixCats.categories, but for the extra package";
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
            };
          });
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
                The path to your nvim config directory in the store. In the base nixCats flake, this is "''${./.}".
              '';
              example = ''"''${./.}/userLuaConfig"'';
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
            extraPackageDefs = mkOption {
              default = {};
              description = ''
                Same as nixCats settings and categories except, you are in charge of making sure
                that the aliases don't collide with any other packageDefinitions
              '';
              type = with types; attrsOf (submodule {
                options = {
                  settings = mkOption {
                    default = packageDefinitions.${config.${defaultPackageName}.packageName}.settings or {};
                    type = (types.attrsOf types.anything);
                    description = ''
                      Same as nixCats.settings except, you are in charge of making sure the aliases don't collide with any other packageDefinitions
                      Will build all included.
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
                    default = packageDefinitions.${config.${defaultPackageName}.packageName}.categories or {};
                    type = (types.attrsOf types.anything);
                    description = "same as nixCats.categories, but for the extra package";
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
                };
              });
            };
            addOverlays = mkOption {
              default = [];
              type = (types.listOf types.anything);
              description = ''A list of overlays to make available to categoryDefinitions (and pkgs in general)'';
              example = ''
                [ (self: super: { vimPlugins = { pluginDerivationName = pluginDerivation; }; }) ]
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
    dependencyOverlays = [ (utils.mergeOverlayLists oldDependencyOverlays options_set.addOverlays) ];
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
      xtraPkgDef = lib.mkIf (user_options_set.extraPackageDefs !={}) options_set.extraPackageDefs;
      finalPrim = lib.mkIf user_options_set.enable [
          (
            (
              if user_options_set.luaPath != "" then (utils.baseBuilder options_set.luaPath)
              else (
                if keepLuaBuilder != null then 
                keepLuaBuilder else 
                builtins.throw "no lua or keepLua builder supplied to mkNixosModules"
              )
            ) { inherit pkgs dependencyOverlays; } newCategoryDefinitions newUserPackageDefinition user_options_set.packageName
          )
        ];
      finalXtra = lib.mkIf (user_options_set.enable && (user_options_set.extraPackageDefs !={}) ) (builtins.attrValues (builtins.mapAttrs (catName: _:
          (
            if user_options_set.luaPath != "" then (utils.baseBuilder options_set.luaPath)
            else (
              if keepLuaBuilder != null then 
              keepLuaBuilder else 
              builtins.throw "no lua or keepLua builder supplied to mkNixosModules"
            )
          )
          { inherit pkgs dependencyOverlays; } newCategoryDefinitions
          xtraPkgDef catName
        ) xtraPkgDef));
        finalUserPkgs = lib.mkIf ( user_options_set.enable || (options_set.enable && (user_options_set.extraPackageDefs !={}) )) (
          if (user_options_set.enable && (user_options_set.extraPackageDefs !={}) )
          then finalPrim ++ finalXtra
          else finalPrim
        );
      in {
        packages = lib.mkIf user_options_set.enable finalUserPkgs;
      }
    ) config.${defaultPackageName}.users;

    options_set = config.${defaultPackageName};
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
    xtraPkgDef = lib.mkIf (options_set ? extraPackageDefs) options_set.extraPackageDefs;
    finalPrim = lib.mkIf options_set.enable [
        (
          (
            if options_set.luaPath != "" then (utils.baseBuilder options_set.luaPath)
            else (
              if keepLuaBuilder != null then 
              keepLuaBuilder else 
              builtins.throw "no lua or keepLua builder supplied to mkNixosModules"
            )
          ) { inherit pkgs dependencyOverlays; } newCategoryDefinitions newSystemPackageDefinition options_set.packageName
        )
      ];
    finalXtra = lib.mkIf (options_set.enable && options_set ? extraPackageDefs ) (builtins.attrValues (builtins.mapAttrs (catName: _:
        (
          if options_set.luaPath != "" then (utils.baseBuilder options_set.luaPath)
          else (
            if keepLuaBuilder != null then 
            keepLuaBuilder else 
            builtins.throw "no lua or keepLua builder supplied to mkNixosModules"
          )
        )
        { inherit pkgs dependencyOverlays; } newCategoryDefinitions
        xtraPkgDef catName
      ) xtraPkgDef));
      finalSystemPkgs = lib.mkIf ( options_set.enable || (options_set.enable && options_set ? extraPackageDefs )) (
        if (options_set.enable && options_set ? extraPackageDefs )
        then finalPrim ++ finalXtra
        else finalPrim
      );
  in
  {
    nixpkgs.overlays = dependencyOverlays;
    users.users = newUserPackageDefinitions;
    environment.systemPackages = lib.mkIf options_set.enable finalSystemPkgs;
  };
}

