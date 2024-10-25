# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
{
  oldDependencyOverlays ? null
  , luaPath ? ""
  , keepLuaBuilder ? null
  , categoryDefinitions ? (_:{})
  , packageDefinitions ? {}
  , defaultPackageName
  , utils
  , nixpkgs ? null
  , extra_pkg_config ? {}
  , ...
}:
{ config, pkgs, lib, ... }: let
  catDef = lib.mkOptionType {
    name = "catDef";
    description = "a function representing categoryDefinitions or a package definition in the packageDefinitions set for nixCats";
    descriptionClass = "noun";
    check = v: builtins.isFunction v;
    merge = loc: defs: let
      recursiveUpdateUntilDRV = lhs: rhs:
        lib.recursiveUpdateUntil (path: lhs: rhs:
            (!((builtins.isAttrs lhs && !lib.isDerivation lhs) && (builtins.isAttrs rhs && !lib.isDerivation rhs)))
          ) lhs rhs;
      values = map (v: v.value) defs;
    in
    arg: builtins.foldl' recursiveUpdateUntilDRV {} (map (v: v arg) values);
  };
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

      out.packages = mkOption {
        type = types.attrsOf types.package;
        visible = false;
        readOnly = true;
        description = "Resulting customized neovim packages.";
      };

      enable = mkOption {
        default = false;
        type = types.bool;
        description = "Enable the ${defaultPackageName} module";
      };

      luaPath = mkOption {
        default = luaPath;
        type = types.str;
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
        replace = mkOption {
          default = null;
          type = types.nullOr catDef;
          description = (literalExpression ''
            Takes a function that receives the package definition set of this package
            and returns a set of categoryDefinitions,
            just like :help nixCats.flake.outputs.categories
            you should use ${pkgs.system} provided in the packageDef set
            to access system specific items.

            If any value is found for categoryDefinitions.replace,
            any inherited values from the package this module was based on, if any, will be overwritten.
            To merge with inherited values, use categoryDefinitions.merge instead, and do not set this value.
          '');
          example = ''
            # see :help nixCats.flake.outputs.categories
            categoryDefinitions.replace = { pkgs, settings, categories, name, ... }@packageDef: { }
          '';
        };
        merge = mkOption {
          default = null;
          type = types.nullOr catDef;
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
          It will cause a build conflict.

          You can have as many nixCats installed per user as you want,
          as long as you obey that rule.

          for information on the values you may return,
          see :help nixCats.flake.outputs.settings
          and :help nixCats.flake.outputs.categories
        '';
        type = with types; nullOr (attrsOf catDef);
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

  };

  config = let
    options_set = config.${defaultPackageName};
    dependencyOverlays = if builtins.isAttrs oldDependencyOverlays then
        lib.genAttrs (builtins.attrNames oldDependencyOverlays)
          (system: pkgs.overlays ++ [(utils.mergeOverlayLists oldDependencyOverlays.${system} options_set.addOverlays)])
      else if builtins.isList oldDependencyOverlays then
      pkgs.overlays ++ [(utils.mergeOverlayLists oldDependencyOverlays options_set.addOverlays)]
      else pkgs.overlays ++ options_set.addOverlays;

    mapToPackages = options_set: dependencyOverlays: (let
      newCategoryDefinitions = utils.mergeCatDefs (
        if options_set.categoryDefinitions.replace != null then options_set.categoryDefinitions.replace else categoryDefinitions
      ) (
        if options_set.categoryDefinitions.merge != null then options_set.categoryDefinitions.merge else (_:{})
      );

      pkgDefs = if (options_set.packages != null)
        then packageDefinitions // options_set.packages else packageDefinitions;

      newLuaBuilder = (if options_set.luaPath != "" then (utils.baseBuilder options_set.luaPath)
        else 
          (if keepLuaBuilder != null
            then keepLuaBuilder else 
            builtins.throw "no luaPath or builder with applied luaPath supplied to mkNixosModules or luaPath module option"));

      newNixpkgs = if config.${defaultPackageName}.nixpkgs_version != null
        then config.${defaultPackageName}.nixpkgs_version else if nixpkgs != null then nixpkgs else builtins.throw "module not based on existing nixCats package, and ${defaultPackageName}.nixpkgs_version is not defined";

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
    mappedPackageAttrs = mapToPackages options_set dependencyOverlays;
    mappedPackages = builtins.attrValues mappedPackageAttrs;
  in
  {
    ${defaultPackageName}.out.packages = lib.mkIf options_set.enable mappedPackageAttrs;
    home.packages = lib.mkIf options_set.enable mappedPackages;
  };

}
