# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
{
  isHomeManager
  , defaultPackageName
  , moduleNamespace ? [ defaultPackageName ]
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
    inherit utils nclib defaultPackageName luaPath packageDefinitions isHomeManager moduleNamespace;
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

    mapToPackages = options_set: dependencyOverlays: (let
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
        modulePkgDefs = pkgmerger utils.deepmergeCats options_set.packageDefinitions.replace options_set.packageDefinitions.merge;
      in pkgmerger stratWithExisting packageDefinitions modulePkgDefs;

      newLuaBuilder = (if options_set.luaPath != "" then (utils.baseBuilder options_set.luaPath)
        else 
          (if keepLuaBuilder != null
            then keepLuaBuilder else 
            builtins.throw "no luaPath or builder with applied luaPath supplied to mkModules or luaPath module option"));

      newNixpkgs = if options_set.nixpkgs_version != null
        then options_set.nixpkgs_version
        else if lib.attrByPath (moduleNamespace ++ [ "nixpkgs_version" ]) null config != null
        then lib.attrByPath (moduleNamespace ++ [ "nixpkgs_version" ]) null config
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

    main_options_set = lib.attrByPath moduleNamespace {} config;
    mappedPackageAttrs = mapToPackages main_options_set (dependencyOverlaysFunc { inherit main_options_set;});
    mappedPackages = builtins.attrValues mappedPackageAttrs;

  in
  (if isHomeManager then (lib.setAttrByPath (moduleNamespace ++ [ "out" ]) {
      packages = lib.mkIf main_options_set.enable mappedPackageAttrs;
    }) // {
    home.packages = lib.mkIf (main_options_set.enable && ! main_options_set.dontInstall) mappedPackages;
  } else (let
    userops = lib.attrByPath (moduleNamespace ++ [ "users" ]) {} config;
    newUserPackageOutputs = builtins.mapAttrs ( uname: user_options_set: {
        packages = lib.mkIf user_options_set.enable (mapToPackages
          user_options_set
          (dependencyOverlaysFunc { inherit main_options_set user_options_set; })
        );
      }
    ) userops;
    newUserPackageDefinitions = builtins.mapAttrs ( uname: user_options_set: {
        packages = lib.mkIf (user_options_set.enable && ! user_options_set.dontInstall) (builtins.attrValues newUserPackageOutputs.${uname}.packages);
      }
    ) userops;
  in (lib.setAttrByPath (moduleNamespace ++ [ "out" ]) {
      users = newUserPackageOutputs;
      packages = lib.mkIf main_options_set.enable mappedPackageAttrs;
    }) // {
    users.users = newUserPackageDefinitions;
    environment.systemPackages = lib.mkIf (main_options_set.enable && ! main_options_set.dontInstall) mappedPackages;
  }));

}
