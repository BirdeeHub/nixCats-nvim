# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
{
  isHomeManager
  , utils ? import ./.
  , nclib ? import ./lib.nix
}: {
  defaultPackageName ? null
  , moduleNamespace ? [ (if defaultPackageName != null then defaultPackageName else "nixCats") ]
  , dependencyOverlays ? null
  , luaPath ? ""
  , keepLuaBuilder ? null
  , categoryDefinitions ? (_:{})
  , packageDefinitions ? {}
  , nixpkgs ? null
  , extra_pkg_config ? {}
  , extra_pkg_params ? {}
  , ...
}:
{ config, pkgs, lib, ... }: {

  imports = [ (import ./mkOpts.nix {
    inherit utils nclib isHomeManager moduleNamespace;
    defaultPackageName = if defaultPackageName != null && packageDefinitions ? "${defaultPackageName}" then defaultPackageName else null;
  }) ];

  config = let
    def_merger = strat: old: new:
      if old != null && new != null
        then if strat == "merge" || strat == "replace"
        then utils.mergeDefs strat [ old new ]
        else new
      else if new != null then new else if old != null then old else (_:{});

    pkg_def_merger = strat: old: new:
      (if builtins.isAttrs old then old else {})
      // (builtins.mapAttrs (n: v: def_merger strat (old.${n} or null) v) (if builtins.isAttrs new then new else {}));

    mapToPackages = main_options_set: options_set: let
      newLuaBuilder = if options_set.luaPath != ""
          then utils.baseBuilder options_set.luaPath
        else if luaPath != ""
          then utils.baseBuilder luaPath
        else if keepLuaBuilder != null
          then keepLuaBuilder
        else builtins.throw "no luaPath supplied to mkModules or luaPath module option";

      catDefs = lib.pipe options_set.categoryDefinitions.merge [
        (def_merger "merge" options_set.categoryDefinitions.replace)
        (def_merger options_set.categoryDefinitions.existing categoryDefinitions)
      ];

      pkgDefs = lib.pipe options_set.packageDefinitions.merge [
        (pkg_def_merger "merge" options_set.packageDefinitions.replace)
        (pkg_def_merger options_set.packageDefinitions.existing packageDefinitions)
      ];

      pkgsoptions = if options_set.nixpkgs_version or null != null
        then options_set.nixpkgs_version
        else if main_options_set.nixpkgs_version or null != null
        then main_options_set.nixpkgs_version
        else nixpkgs;

      depOvers = (if builtins.isAttrs dependencyOverlays
        then nclib.warnfn ''
          # NixCats deprecation warning
          Do not wrap your dependencyOverlays list in a set of systems.
          They should just be a list.
          Use `utils.fixSystemizedOverlay` if required to fix occasional malformed flake overlay outputs
          See :h nixCats.flake.outputs.getOverlays
          '' dependencyOverlays.${pkgs.system}
        else if builtins.isList dependencyOverlays
          then dependencyOverlays
          else []) ++ (main_options_set.addOverlays or []) ++ (options_set.addOverlays or []);

      extra_params = if builtins.isAttrs extra_pkg_params then extra_pkg_params else {};
      extra_config = if builtins.isAttrs extra_pkg_config then extra_pkg_config else {};

      newPkgsParams = if extra_params == {} && extra_config == {} && pkgsoptions == null
        then if depOvers != []
          then { pkgs = pkgs.appendOverlays depOvers; }
          else { inherit pkgs; }
        else {
          nixpkgs = if pkgsoptions != null then pkgsoptions else pkgs;
          pkgs = if pkgsoptions == null then pkgs else null;
          dependencyOverlays = (if pkgsoptions != null then pkgs.overlays else []) ++ depOvers;
          inherit (pkgs) system;
          extra_pkg_params = extra_params;
          extra_pkg_config = (if pkgsoptions != null then pkgs.config else {}) // extra_config;
        };

    in lib.pipe options_set.packageNames [
      (builtins.map (name: { inherit name; value = newLuaBuilder newPkgsParams catDefs pkgDefs name; }))
      builtins.listToAttrs
    ];

    main_options_set = lib.attrByPath moduleNamespace {} config;
    mappedPackageAttrs = mapToPackages {} main_options_set;
    mappedPackages = builtins.attrValues (lib.attrByPath (moduleNamespace ++ [ "out" "packages" ]) {} config);
  in
  if isHomeManager
  then (lib.setAttrByPath (moduleNamespace ++ [ "out" ]) { packages = lib.mkIf main_options_set.enable mappedPackageAttrs; })
    // { home.packages = lib.mkIf (main_options_set.enable && ! main_options_set.dontInstall) mappedPackages; }
  else (let
    userops = lib.attrByPath (moduleNamespace ++ [ "users" ]) {} config;
  in (lib.setAttrByPath (moduleNamespace ++ [ "out" ]) {
      users = builtins.mapAttrs (_: user_options_set: {
        packages = lib.mkIf user_options_set.enable (mapToPackages main_options_set user_options_set);
      }) userops;
      packages = lib.mkIf main_options_set.enable mappedPackageAttrs;
  }) // {
    users.users = builtins.mapAttrs (uname: user_options_set: {
      packages = lib.mkIf (user_options_set.enable && ! user_options_set.dontInstall)
        (builtins.attrValues (lib.attrByPath (moduleNamespace ++ [ "out" "users" uname "packages" ]) {} config));
    }) userops;
    environment.systemPackages = lib.mkIf (main_options_set.enable && ! main_options_set.dontInstall) mappedPackages;
  });
}
