{ 
  nixpkgs
  , inputs
  , otherOverlays
  , baseBuilder
  , luaPath ? ""
  , keepLuaBuilder ? null
  , pkgs
  , categoryDefinitions
  , packageDefinitions
  , defaultPackageName
}: utils:

{ config, ... }@misc: {

  options = with nixpkgs.lib; {

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
        description = ''A list of overlays to make available to categoryDefinitions'';
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
      pkgsAdditions = mkOption {
        default = {};
        type = (types.attrsOf types.anything);
        description = ''things to add to pkgs outside of system and overlays'';
        example = ''{ config.allowUnfree = true; }'';
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

  };

  config = let
    options_set = config.${defaultPackageName};
    newOtherOverlays = [ (utils.mergeOverlayLists otherOverlays options_set.addOverlays) ];
    newPkgs = import nixpkgs ({
      inherit (pkgs) system;
      overlays = newOtherOverlays ++ [
          # here we can also add the regular inputs from other nixCats like so
          (utils.standardPluginOverlay (inputs // options_set.addInputs))
        ];
    } // options_set.pkgsAdditions);
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
    home.packages = nixpkgs.lib.mkIf options_set.enable
      [ (
          (
            if options_set.luaPath != "" then (baseBuilder options_set.luaPath)
            else (
              if keepLuaBuilder != null then 
              keepLuaBuilder else 
              builtins.throw "no lua or keepLua builder supplied to mkNixosModules"
            )
          ) newPkgs newCategoryDefinitions newSystemPackageDefinition options_set.packageName
        )
      ];
  };

}

