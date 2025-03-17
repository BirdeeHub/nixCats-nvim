# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
{
  isHomeManager
  , defaultPackageName ? null
  , moduleNamespace ? [ (if defaultPackageName != null then defaultPackageName else "nixCats") ]
  , oldDependencyOverlays ? null
  , luaPath ? ""
  , keepLuaBuilder ? null
  , categoryDefinitions ? (_:{})
  , packageDefinitions ? {}
  , utils
  , nclib
  , nixpkgs ? null
  , ...
}@inhargs:
{ config, pkgs, lib, ... }: {

  imports = [ (import ./mkOpts.nix {
    inherit utils nclib defaultPackageName luaPath packageDefinitions isHomeManager moduleNamespace;
  }) ];

  config = let
    dependencyOverlaysFunc = { main_options_set, user_options_set ? {} }:
      (main_options_set.addOverlays or [])
        ++ (user_options_set.addOverlays or [])
        ++ (
          if builtins.isAttrs oldDependencyOverlays
          then builtins.trace ''
            deprecated wrapping of dependencyOverlays list in a set of systems.
            Use `utils.fixSystemizedOverlay` if required to fix occasional malformed flake overlay outputs
            See :h nixCats.flake.outputs.getOverlays
            '' oldDependencyOverlays.${pkgs.system}
          else if builtins.isList oldDependencyOverlays
            then oldDependencyOverlays
            else []
        );

    mapToPackages = options_set: depOvers: (let
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

      newPkgsParams = let
        pkgsoptions = if options_set.nixpkgs_version != null
          then options_set.nixpkgs_version
          else if lib.attrByPath (moduleNamespace ++ [ "nixpkgs_version" ]) null config != null
          then lib.attrByPath (moduleNamespace ++ [ "nixpkgs_version" ]) null config
          else nixpkgs;
        nixpkgspath = if pkgsoptions != null then pkgsoptions else pkgs;
        extra_pkg_params = if builtins.isAttrs (inhargs.extra_pkg_params or null) then inhargs.extra_pkg_params else {};
        extra_pkg_config = if builtins.isAttrs (inhargs.extra_pkg_config or null) then inhargs.extra_pkg_config else {};
        dependencyOverlays = lib.optional (depOvers != []) (utils.mergeOverlays depOvers);
      in if extra_pkg_params == {} && extra_pkg_config == {} && pkgsoptions == null
        then if dependencyOverlays != []
          then {
            pkgs = pkgs.appendOverlays dependencyOverlays;
          } else {
            inherit pkgs;
          }
        else {
          nixpkgs = nixpkgspath;
          extra_pkg_config = pkgs.config // extra_pkg_config;
          inherit (pkgs) system;
          dependencyOverlays = pkgs.overlays ++ dependencyOverlays;
          inherit extra_pkg_params;
        };

    in (builtins.listToAttrs (builtins.map (catName: let
      in {
        name = catName;
        value = newLuaBuilder newPkgsParams newCategoryDefinitions pkgDefs catName;
      }) options_set.packageNames))
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
    newUserPackageDefinitions = builtins.mapAttrs (uname: user_options_set: {
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
