# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
with builtins; rec {
  # These are to be exported in flake outputs
  utils = {
    # The big function that does everything
    baseBuilder =
      luaPath:
      {
        nixpkgs
        , system
        , extra_pkg_config ? {}
        , dependencyOverlays ? null
        , nixCats_passthru ? {}
        , ...
      }:
      categoryDefinitions:
      packageDefinitions: name:
      nixpkgs.lib.makeOverridable (import ../builder) {
        inherit luaPath categoryDefinitions packageDefinitions name
        nixpkgs system extra_pkg_config dependencyOverlays nixCats_passthru;
      };


    templates = import ../templates;

    # allows for inputs named plugins-something to be turned into plugins automatically
    standardPluginOverlay = (import ./autoPluginOverlay.nix).standardPluginOverlay;

  # same as standardPluginOverlay except if you give it `plugins-foo.bar`
  # you can `pkgs.neovimPlugins.foo-bar` and still `packadd foo.bar`
    sanitizedPluginOverlay = (import ./autoPluginOverlay.nix).sanitizedPluginOverlay;

    # returns a merged set of definitions, with new overriding old.
    # updates anything it finds that isn't another set.
    # this means it works slightly differently for environment variables
    # because each one will be updated individually rather than at a category level.
    mergeCatDefs = oldCats: newCats:
      (packageDef: lib.recursiveUpdateUntilDRV (oldCats packageDef) (newCats packageDef));

    # recursiveUpdate each overlay output to avoid issues where
    # two overlays output a set of the same name when importing from other nixCats.
    # Merges everything into 1 overlay
    mergeOverlayLists = oldOverlist: newOverlist: self: super: let
      oldOversMapped = map (value: value self super) oldOverlist;
      newOversMapped = map (value: value self super) newOverlist;
      combinedOversCalled = oldOversMapped ++ newOversMapped;
      mergedOvers = foldl' lib.recursiveUpdateUntilDRV { } combinedOversCalled;
    in
    mergedOvers;

    # if your dependencyOverlays is a list rather than a system-wrapped set,
    # to deal with when other people output an overlay wrapped in a system variable
    # you may call the following function on it.
    fixSystemizedOverlay = overlaysSet: outfunc:
      (final: prev: if !(overlaysSet ? prev.system) then {}
        else (outfunc prev.system) final prev);

    # Simple helper function for mergeOverlayLists
    # If dependencyOverlays is an attrset, system string is required.
    # If dependencyOverlays is a list, system string is ignored
    # if invalid type or system, returns an empty list
    safeOversList = { dependencyOverlays, system ? null }:
      if isAttrs dependencyOverlays && system == null then
        throw "dependencyOverlays is a set, but no system was provided"
      else if isAttrs dependencyOverlays && dependencyOverlays ? system then
        dependencyOverlays.${system}
      else if isList dependencyOverlays then
        dependencyOverlays
      else [];

    # makes a default package and then one for each name in packageDefinitions
    mkPackages = finalBuilder: packageDefinitions: defaultName:
      { default = finalBuilder defaultName; }
      // utils.mkExtraPackages finalBuilder packageDefinitions;

    mkExtraPackages = finalBuilder: packageDefinitions:
    (mapAttrs (name: _: finalBuilder name) packageDefinitions);

    makeOverlays = 
      luaPath:
      {
        nixpkgs
        , extra_pkg_config ? {}
        , dependencyOverlays ? null
        , nixCats_passthru ? {}
        , ...
      }@pkgsParams:
      categoryDefFunction:
      packageDefinitions: defaultName: let
        keepLuaBuilder = if isFunction luaPath then luaPath else utils.baseBuilder luaPath;
        makeOverlay = name: final: prev: {
          ${name} = keepLuaBuilder (pkgsParams // { inherit (final) system; }) categoryDefFunction packageDefinitions name;
        };
        overlays = (mapAttrs (name: _: makeOverlay name) packageDefinitions) // { default = (makeOverlay defaultName); };
      in overlays;

    makeOverlaysWithMultiDefault = 
      luaPath:
      {
        nixpkgs
        , extra_pkg_config ? {}
        , dependencyOverlays ? null
        , nixCats_passthru ? {}
        , ...
      }@pkgsParams:
      categoryDefFunction:
      packageDefinitions: defaultName: let
        keepLuaBuilder = if isFunction luaPath then luaPath else utils.baseBuilder luaPath;
        makeOverlay = name: final: prev: {
          ${name} = keepLuaBuilder (pkgsParams // { inherit (final) system; }) categoryDefFunction packageDefinitions name;
        };
        overlays = (mapAttrs (name: _: makeOverlay name) packageDefinitions) // {
          default = (utils.makeMultiOverlay luaPath pkgsParams categoryDefFunction packageDefinitions defaultName (attrNames packageDefinitions));
        };
      in overlays;

    easyMultiOverlayNamespaced = package: importName: let
      allnames = builtins.attrNames package.passthru.packageDefinitions;
    in
    (final: prev: {
      ${importName} = listToAttrs (map (name:
          lib.nameValuePair name (package.override { inherit name; inherit (prev) system; })
        ) allnames);
    });

    mkAllPackages = package: let
      allnames = builtins.attrNames package.passthru.packageDefinitions;
    in
    listToAttrs (map (name:
      lib.nameValuePair name (package.override { inherit name; })
    ) allnames);

    mkAllWithDefault = package:
    { default = package; } // (utils.mkAllPackages package);

    easyMultiOverlay = package: let
      allnames = builtins.attrNames package.passthru.packageDefinitions;
    in
    (final: prev: listToAttrs (map (name:
      lib.nameValuePair name (package.override { inherit name; inherit (prev) system; })
    ) allnames));

    easyNamedOvers = package: let
      allnames = builtins.attrNames package.passthru.packageDefinitions;
      mapfunc = map (name:
        lib.nameValuePair name (final: prev: {
          ${name} = package.override { inherit (prev) system; };
        }));
    in
    listToAttrs (mapfunc allnames);

    # maybe you want multiple nvim packages in the same system and want
    # to add them like pkgs.MyNeovims.packageName when you install them?
    # both to keep it organized and also to not have to worry about naming conflicts with programs?
    makeMultiOverlay = luaPath:
      {
        nixpkgs
        , extra_pkg_config ? {}
        , dependencyOverlays ? null
        , nixCats_passthru ? {}
        , ...
      }@pkgsParams:
      categoryDefFunction:
      packageDefinitions:
      importName:
      namesIncList:
      (final: prev: {
        ${importName} = listToAttrs (
          map
            (name: let
              keepLuaBuilder = if builtins.isFunction luaPath then luaPath else utils.baseBuilder luaPath;
            in
              {
                inherit name;
                value =  keepLuaBuilder (pkgsParams // { inherit (final) system; }) categoryDefFunction packageDefinitions name;
              }
            ) namesIncList
          );
        }
      );

    mkNixosModules = {
      dependencyOverlays
      , luaPath ? ""
      , keepLuaBuilder ? null
      , categoryDefinitions
      , packageDefinitions
      , defaultPackageName
      , nixpkgs
      , extra_pkg_config ? {}
      , ... }:
      (import ./nixosModule.nix {
        oldDependencyOverlays = dependencyOverlays;
        inherit nixpkgs luaPath keepLuaBuilder categoryDefinitions
          packageDefinitions defaultPackageName extra_pkg_config utils;
      });

    mkHomeModules = {
      dependencyOverlays
      , luaPath ? ""
      , keepLuaBuilder ? null
      , categoryDefinitions
      , packageDefinitions
      , defaultPackageName
      , nixpkgs
      , extra_pkg_config ? {}
      , ... }:
      (import ./homeManagerModule.nix {
        oldDependencyOverlays = dependencyOverlays;
        inherit nixpkgs luaPath keepLuaBuilder categoryDefinitions
          packageDefinitions defaultPackageName extra_pkg_config utils;
      });

    # flake-utils' main function, because its all I used
    # Builds a map from <attr>=value to <attr>.<system>=value for each system
    eachSystem = systems: f:
      let
        # Merge together the outputs for all systems.
        op = attrs: system:
          let
            ret = f system;
            op = attrs: key: attrs //
                {
                  ${key} = (attrs.${key} or { })
                    // { ${system} = ret.${key}; };
                }
            ;
          in
          foldl' op attrs (attrNames ret);
      in
      foldl' op { }
        (systems
          ++ # add the current system if --impure is used
            (if builtins ? currentSystem then
               if elem currentSystem systems
               then []
               else [ currentSystem ]
            else []));

    # in case someoneone wants flake-utils but for only 1 output,
    # and didnt know genAttrs is great as a bySystems
    bySystems = lib.genAttrs;

    # you can use this to make values in the tables generated
    # for the nixCats plugin using lua literals.
    # i.e. cache_location = mkLuaInline "vim.fn.stdpath('cache')",
    inherit (import ../builder/ncTools.nix) mkLuaInline;

  };

  # https://github.com/NixOS/nixpkgs/blob/nixos-23.05/lib/attrsets.nix
  lib = {
    isDerivation = value: value.type or null == "derivation";

    recursiveUpdateUntil = pred: lhs: rhs:
      let f = attrPath:
        zipAttrsWith (n: values:
          let here = attrPath ++ [n]; in
          if length values == 1
          || pred here (elemAt values 1) (head values) then
            head values
          else
            f here values
        );
      in f [] [rhs lhs];

    recursiveUpdateUntilDRV = lhs: rhs:
      lib.recursiveUpdateUntil (path: lhs: rhs:
            # I added this check for derivation because a category can be just a derivation.
            # otherwise it would squish our single derivation category rather than update.
          (!((isAttrs lhs && !lib.isDerivation lhs) && (isAttrs rhs && !lib.isDerivation rhs)))
        ) lhs rhs;

    genAttrs =
      names:
      f:
      listToAttrs (map (n: lib.nameValuePair n (f n)) names);

    nameValuePair =
      name:
      value:
      { inherit name value; };
  };
}

