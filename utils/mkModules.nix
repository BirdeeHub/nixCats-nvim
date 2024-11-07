# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
{
  isHomeManager
  , defaultPackageName
  , oldDependencyOverlays ? null
  , luaPath ? ""
  , keepLuaBuilder ? null
  , categoryDefinitions ? (_:{})
  , packageDefinitions ? {}
  , utils
  , my_lib
  , nixpkgs ? null
  , extra_pkg_config ? {}
  , ...
}:
{ config, pkgs, lib, ... }: let
  catDef = my_lib.mkCatDefType lib.mkOptionType;
in {

  options = with lib; {

    ${defaultPackageName} = {

      nixpkgs_version = mkOption {
        default = null;
        type = types.nullOr (types.anything);
        description = ''
          a different nixpkgs import to use. By default will use the one from the flake, or throw if none exists.
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
          addOverlays = [ (self: super: { vimPlugins = { pluginDerivationName = pluginDerivation; }; }) ]
        '');
      };

      enable = mkOption {
        default = false;
        type = types.bool;
        description = "Enable the ${defaultPackageName} module";
      };

      luaPath = mkOption {
        default = luaPath;
        type = types.oneOf [ types.str types.path ];
        description = (literalExpression ''
          The path to your nvim config directory in the store.
          In the base nixCats flake, this is "${./.}".
        '');
        example = (literalExpression "${./.}/userLuaConfig");
      };

      packageNames = mkOption {
        default = if packageDefinitions ? defaultPackageName then [ "${defaultPackageName}" ] else [];
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
          description = (literalExpression ''
            see :help nixCats.flake.outputs.categories
            uses utils.mergeCatDefs to recursively update old categories with new values
            see :help nixCats.flake.outputs.exports for more info on the merge strategy options
          '');
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
          type = with types; nullOr (attrsOf (catDef "replace"));
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
          type = with types; nullOr (attrsOf (catDef "replace"));
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
          and without addOverlays or nixpkgs_version
        '';
        type = with types; attrsOf (submodule {
          options = {
            enable = mkOption {
              default = false;
              type = types.bool;
              description = "Enable the ${defaultPackageName} module for a user";
            };

            nixpkgs_version = mkOption {
              default = null;
              type = types.nullOr (types.anything);
              description = ''
                a different nixpkgs import to use for this users nvim.
                By default will use the one from ${defaultPackageName}.nixpkgs_version, or flake, or throw if none exists.
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
                This per user version of addOverlays is merged with the value of ${defaultPackageName}.addOverlays 
              '';
              example = (lib.literalExpression ''
                addOverlays = [ (self: super: { vimPlugins = { pluginDerivationName = pluginDerivation; }; }) ]
              '');
            };

            luaPath = mkOption {
              default = luaPath;
              type = types.oneOf [ types.str types.path ];
              description = ''
                The path to your nvim config directory in the store.
                In the base nixCats flake, this is "''${./.}".
              '';
              example = ''"''${./.}/userLuaConfig"'';
            };

            packageNames = mkOption {
              default = if packageDefinitions ? defaultPackageName then [ "${defaultPackageName}" ] else [];
              type = (types.listOf types.str);
              description = ''A list of packages from packageDefinitions to include'';
              example = ''
                [ "nixCats" ]
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
                  categoryDefinitions = { pkgs, settings, categories, name, ... }@packageDef: { }
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
                  categoryDefinitions = { pkgs, settings, categories, name, ... }@packageDef: { }
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
                type = with types; nullOr (attrsOf (catDef "replace"));
                example = ''
                  nixCats.users.<USER>.packages = { 
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
                type = with types; nullOr (attrsOf (catDef "replace"));
                example = ''
                  nixCats.users.<USER>.packages = { 
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
    });
  };

  config = let
    dependencyOverlaysFunc = { main_options_set, user_options_set ? { addOverlays = []; } }: let
      overlaylists = [ (utils.mergeOverlayLists main_options_set.addOverlays user_options_set.addOverlays) ];
    in if builtins.isAttrs oldDependencyOverlays then
        lib.genAttrs (builtins.attrNames oldDependencyOverlays)
          (system: pkgs.overlays ++ [(utils.mergeOverlayLists oldDependencyOverlays.${system} overlaylists)])
      else if builtins.isList oldDependencyOverlays then
      pkgs.overlays ++ [(utils.mergeOverlayLists oldDependencyOverlays overlaylists)]
      else pkgs.overlays ++ overlaylists;

    mapToPackages = options_set: dependencyOverlays: atp: (let
      getStratWithExisting = enumstr: if enumstr == "merge"
        then utils.deepmergeCats
        else if enumstr == "replace"
        then utils.mergeCatDefs
        else (_: r: r);

      newCategoryDefinitions = let
        combineModDeps = replacements: merges: utils.deepmergeCats (
          if replacements != null then replacements else (_:{})
        ) (if merges != null then merges else (_:{}));
        stratWithExisting = getStratWithExisting options_set.categoryDefinitions.existing;
        moduleCatDefs = combineModDeps options_set.categoryDefinitions.replace options_set.categoryDefinitions.merge;
      in stratWithExisting categoryDefinitions moduleCatDefs;

      pkgDefs = let
        pkgmerger = strat: old: new: let
          oldAttrs = if builtins.isAttrs old then old else {};
          newAttrs = if builtins.isAttrs new then new else {};
          merged = builtins.mapAttrs (n: v: if oldAttrs ? ${n} then strat oldAttrs.${n} v else v) newAttrs;
        in
        oldAttrs // merged;
        stratWithExisting = getStratWithExisting options_set.packageDefinitions.existing;
        modulePkgDefs = let
          # TODO: this `repments` step can be removed when options_set.packages is removed
          # In addition, `mapToPackages` will once again no longer need to know its attrpath
          repments = if options_set.packages != null then builtins.trace (let
            basepath = builtins.concatStringsSep "." atp;
          in ''
            Deprecation warning: ${basepath}.packages renamed to: ${basepath}.packageDefinitions.replace
            Done in order to achieve consistency with ${basepath}.categoryDefinitions module options, and provide better control
          '') (pkgmerger utils.mergeCatDefs options_set.packages options_set.packageDefinitions.replace)
            else options_set.packageDefinitions.replace;
        in
        pkgmerger utils.deepmergeCats repments options_set.packageDefinitions.merge;
      in pkgmerger stratWithExisting packageDefinitions modulePkgDefs;

      newLuaBuilder = (if options_set.luaPath != "" then (utils.baseBuilder options_set.luaPath)
        else 
          (if keepLuaBuilder != null
            then keepLuaBuilder else 
            builtins.throw "no luaPath or builder with applied luaPath supplied to mkModules or luaPath module option"));

      newNixpkgs = if options_set.nixpkgs_version != null
        then options_set.nixpkgs_version
        else if config.${defaultPackageName}.nixpkgs_version != null
        then config.${defaultPackageName}.nixpkgs_version
        else if nixpkgs != null
        then nixpkgs else builtins.throw "module not based on existing nixCats package, and ${defaultPackageName}.nixpkgs_version is not defined";

    in (builtins.listToAttrs (builtins.map (catName: let
        boxedCat = newLuaBuilder {
          nixpkgs = newNixpkgs;
          extra_pkg_config = extra_pkg_config // pkgs.config;
          inherit (pkgs) system;
          inherit dependencyOverlays;
        } newCategoryDefinitions pkgDefs catName;
      in
        { name = catName; value = boxedCat; }) options_set.packageNames))
    );

    main_options_set = config.${defaultPackageName};
    mappedPackageAttrs = mapToPackages main_options_set (dependencyOverlaysFunc { inherit main_options_set;}) [ "${defaultPackageName}" ];
    mappedPackages = builtins.attrValues mappedPackageAttrs;

  in
  (if isHomeManager then {
    ${defaultPackageName}.out.packages = lib.mkIf main_options_set.enable mappedPackageAttrs;
    home.packages = lib.mkIf main_options_set.enable mappedPackages;
  } else (let
    newUserPackageDefinitions = builtins.mapAttrs ( uname: _: let
      user_options_set = config.${defaultPackageName}.users.${uname};
      in {
        packages = lib.mkIf user_options_set.enable (builtins.attrValues (mapToPackages
          user_options_set
          (dependencyOverlaysFunc { inherit main_options_set user_options_set; })
          [ defaultPackageName "users" uname ]
        ));
      }
    ) config.${defaultPackageName}.users;
    newUserPackageOutputs = builtins.mapAttrs ( uname: _: let
      user_options_set = config.${defaultPackageName}.users.${uname};
      in {
        packages = lib.mkIf user_options_set.enable (mapToPackages
          user_options_set
          (dependencyOverlaysFunc { inherit main_options_set user_options_set; })
          [ defaultPackageName "users" uname ]
        );
      }
    ) config.${defaultPackageName}.users;
  in {
    ${defaultPackageName}.out = {
      users = newUserPackageOutputs;
      packages = lib.mkIf main_options_set.enable mappedPackageAttrs;
    };
    users.users = newUserPackageDefinitions;
    environment.systemPackages = lib.mkIf main_options_set.enable mappedPackages;
  }));

}
