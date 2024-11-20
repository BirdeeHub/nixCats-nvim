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
  , nclib
  , nixpkgs ? null
  , extra_pkg_config ? {}
  , ...
}:
{ config, pkgs, lib, ... }: {

  imports = [ (import ./mkOpts.nix {
    inherit nclib defaultPackageName luaPath packageDefinitions isHomeManager;
  }) ];

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
            Old option will be removed before 2025
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
        then nixpkgs
        else pkgs;

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
    home.packages = lib.mkIf (main_options_set.enable && ! main_options_set.dontInstall) mappedPackages;
  } else (let
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
    newUserPackageDefinitions = builtins.mapAttrs ( uname: _: let
      user_options_set = config.${defaultPackageName}.users.${uname};
      in {
        packages = lib.mkIf (user_options_set.enable && ! user_options_set.dontInstall) (builtins.attrValues newUserPackageOutputs.${uname}.packages);
      }
    ) config.${defaultPackageName}.users;
  in {
    ${defaultPackageName}.out = {
      users = newUserPackageOutputs;
      packages = lib.mkIf main_options_set.enable mappedPackageAttrs;
    };
    users.users = newUserPackageDefinitions;
    environment.systemPackages = lib.mkIf (main_options_set.enable && ! main_options_set.dontInstall) mappedPackages;
  }));

}
