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
      luaPath = mkOption {
        default = luaPath;
        type = types.str;
        description = ''
          The path to your nvim config directory in the store.
          In the base nixCats flake, this is "''${./.}".
        '';
        example = ''"''${./.}/systemLuaConfig"'';
      };
      packageNames = mkOption {
        default = [ "${defaultPackageName}" ];
        type = (types.listOf types.str);
        description = ''A list of packages from packageDefinitions to include'';
        example = ''
          [ "nixCats" ]
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
      packages = mkOption {
        default = null;
        description = ''
          Same as nixCats settings and categories except, you are in charge of making sure
          that the aliases don't collide with any other packageDefinitions
          Will build all included.
        '';
        type = with types; nullOr (attrsOf (submodule {
          options = {
            definition = mkOption {
              default = null;
              type = nullOr (functionTo (attrsOf anything));
              description = "same as nixCats.categories, but for the extra package";
              example = ''
                { pkgs, ... }: {
                  settings = {
                    wrapRc = true;
                    configDirName = "nixCats-nvim";
                    viAlias = false;
                    vimAlias = false;
                    # nvimSRC = inputs.neovim;
                    customAliases = [ "nixCats" ];
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
                }
              '';
            };
          };
        }));
      };
    };

  };

  config = let
    options_set = config.${defaultPackageName};
    dependencyOverlays = oldDependencyOverlays // {
      ${pkgs.system} = [
        (utils.mergeOverlayLists oldDependencyOverlays.${pkgs.system} options_set.addOverlays)
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
    in (
      builtins.map (catName: _:
        newLuaBuilder { inherit pkgs dependencyOverlays; } newCategoryDefinitions pkgDefs catName
      ) options_set.packageNames)
    );
  in
  {
    nixpkgs.overlays = dependencyOverlays.${pkgs.system};
    home.packages = lib.mkIf (options_set.enable) mapToPackages options_set dependencyOverlays;
  };

}

