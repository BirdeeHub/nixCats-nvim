# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
with builtins; rec {
  # NOTE: This utils set is the entire public interface for nixCats
  utils = {
    # The big function that does everything
    baseBuilder =
      luaPath:
      {
        nixpkgs
        , system ? (nixpkgs.system or builtins.system or import ../builder/builder_error.nix)
        , extra_pkg_config ? {}
        , dependencyOverlays ? null
        , nixCats_passthru ? {}
        , ...
      }:
      categoryDefinitions:
      packageDefinitions: name: let
        # validate channel, regardless of its type
        # normalize to something that has lib and outPath in it
        # so that overriders can always use it as expected
        isPkgs = nixpkgs ? path && nixpkgs ? lib && nixpkgs ? config && nixpkgs ? system;
        isNixpkgs = nixpkgs ? lib && nixpkgs ? outPath;
        nixpkgspath = nixpkgs.path or nixpkgs.outPath or nixpkgs;
        newnixpkgs = if isPkgs then nixpkgs // { outPath = nixpkgspath; }
          else if isNixpkgs then nixpkgs
          else {
            lib = nixpkgs.lib or import "${nixpkgspath}/lib";
            outPath = nixpkgspath;
          };
      in
      newnixpkgs.lib.makeOverridable (import ../builder) {
        nixpkgs = newnixpkgs;
        inherit luaPath categoryDefinitions packageDefinitions name
        system extra_pkg_config dependencyOverlays nixCats_passthru;
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
      (packageDef: lib.recUpdateHandleInlineORdrv (oldCats packageDef) (newCats packageDef));

    # allows category list definitions to be merged
    deepmergeCats = oldCats: newCats:
      (packageDef: lib.recursiveUpdateWithMerge (oldCats packageDef) (newCats packageDef));

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

    mkNixosModules = {
      dependencyOverlays ? null
      , luaPath ? ""
      , keepLuaBuilder ? null
      , categoryDefinitions ? (_:{})
      , packageDefinitions ? {}
      , defaultPackageName
      , nixpkgs ? null
      , extra_pkg_config ? {}
      , ... }:
      (import ./mkModules.nix {
        isHomeManager = false;
        oldDependencyOverlays = dependencyOverlays;
        my_lib = lib;
        inherit nixpkgs luaPath keepLuaBuilder categoryDefinitions
          packageDefinitions defaultPackageName extra_pkg_config utils;
      });

    mkHomeModules = {
      dependencyOverlays ? null
      , luaPath ? ""
      , keepLuaBuilder ? null
      , categoryDefinitions ? (_:{})
      , packageDefinitions ? {}
      , defaultPackageName
      , nixpkgs ? null
      , extra_pkg_config ? {}
      , ... }:
      (import ./mkModules.nix {
        isHomeManager = true;
        oldDependencyOverlays = dependencyOverlays;
        my_lib = lib;
        inherit nixpkgs luaPath keepLuaBuilder categoryDefinitions
          packageDefinitions defaultPackageName extra_pkg_config utils;
      });

    # you can use this to make values in the tables generated
    # for the nixCats plugin using lua literals.
    # i.e. cache_location = utils.n2l.types.inline-safe.mk "vim.fn.stdpath('cache')",
    n2l = import ./n2l.nix;

    mkLuaInline = trace "utils.mkLuaInline renamed to utils.n2l.types.inline-safe.mk, due to be removed before 2025" utils.n2l.types.inline-safe.mk;

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

    catsWithDefault = categories: attrpath: defaults: subcategories: let
      include_path = let
        flattener = cats: let
          mapper = attrs: map (v: if isAttrs v then mapper v else v) (attrValues attrs);
          flatten = accum: LoLoS: foldl' (acc: v: if any (i: isList i) v then flatten acc v else acc ++ [ v ]) accum LoLoS;
        in flatten [] (mapper cats);

        mapToSetOfPaths = cats: let
          removeNullPaths = attrs: lib.filterAttrsRecursive (n: v: v != null) attrs;
          mapToPaths = attrs: lib.mapAttrsRecursiveCond (as: ! lib.isDerivation as) (path: v: if v == true then path else null) attrs;
        in removeNullPaths (mapToPaths cats);

        result = let
          final_cats = lib.attrByPath attrpath false categories;
          allIncPaths = flattener (mapToSetOfPaths final_cats);
        in if isAttrs final_cats && ! lib.isDerivation final_cats && allIncPaths != []
          then head allIncPaths
          else []; 
      in
      result;

      toMerge = let
        firstGet = if isAttrs subcategories && ! lib.isDerivation subcategories
          then lib.attrByPath include_path [] subcategories
          else if isList subcategories then subcategories else [ subcategories ];

        fIncPath = if isAttrs firstGet && ! lib.isDerivation firstGet
          then include_path ++ [ "default" ] else include_path;

        normed = let
          listType = if isAttrs firstGet && ! lib.isDerivation firstGet
            then lib.attrByPath fIncPath [] subcategories
            else if isList firstGet then firstGet else [ firstGet ];
          attrType = let
            pre = if isAttrs firstGet && ! lib.isDerivation firstGet
              then lib.attrByPath fIncPath {} subcategories
              else firstGet;
            basename = if fIncPath != [] then tail fIncPath else "default";
            fin = if isAttrs pre && ! lib.isDerivation pre then pre else { ${basename} = pre; };
          in
          fin;
        in
        if isList defaults then listType else if isAttrs defaults then attrType else throw "defaults must be a list or a set";

        final = lib.setAttrByPath fIncPath (if isList defaults then normed ++ defaults else { inherit normed; default = defaults; });
      in
      builtins.trace ''
        nixCats.utils.catsWithDefault is being deprecated, due to be removed before 2025.

        It is being removed due to not playing well
        with merging categoryDefinitions together.

        A new, more capable method has been added.

        To create default values, use extraCats section of categoryDefinitions
        as outlined in :h nixCats.flake.outputs.categoryDefinitions.default_values,
        and demonstrated in the main example template
      '' final;

    in
    if isAttrs subcategories && ! lib.isDerivation subcategories then
      lib.recUpdateHandleInlineORdrv subcategories toMerge
    else toMerge;

  };

  # https://github.com/NixOS/nixpkgs/blob/nixos-23.05/lib/attrsets.nix
  lib = {
    isDerivation = value: value.type or null == "derivation";

    updateUntilPred = path: lhs: rhs:
      lib.isDerivation lhs || lib.isDerivation rhs
      || utils.n2l.member lhs || utils.n2l.member rhs
      || ! isAttrs lhs || ! isAttrs rhs;

    recursiveUpdateUntilDRV = lib.recUpUntilWpicker { pred = path: lhs: rhs:
      lib.isDerivation lhs || lib.isDerivation rhs || ! isAttrs lhs || ! isAttrs rhs; };

    recUpdateHandleInlineORdrv = lib.recUpUntilWpicker { pred = lib.updateUntilPred; };

    unique = foldl' (acc: e: if elem e acc then acc else acc ++ [ e ]) [];

    recursiveUpdateWithMerge = lib.recUpUntilWpicker {
      pred = lib.updateUntilPred;
      picker = left: right:
        if isList left && isList right
          then lib.unique (left ++ right)
        # category lists can contain mixes of sets and derivations.
        # But they are both attrsets according to typeOf, so we dont need a check for that.
        else if isList left && all (lv: typeOf lv == typeOf right) left then
          if elem right left then left else left ++ [ right ]
        else if isList right && all (rv: typeOf rv == typeOf left) right then
          if elem left right then right else [ left ] ++ right
        else right;
    };

    genAttrs =
      names:
      f:
      listToAttrs (map (n: lib.nameValuePair n (f n)) names);

    nameValuePair =
      name:
      value:
      { inherit name value; };

    recUpUntilWpicker = { pred ? (path: lh: rh: ! isAttrs lh || ! isAttrs rh), picker ? (l: r: r) }: lhs: rhs: let
      f = attrPath:
        zipAttrsWith (n: values:
          let here = attrPath ++ [n]; in
          if length values == 1 then
            head values
          else if pred here (elemAt values 1) (head values) then
            picker (elemAt values 1) (head values)
          else
            f here values
        );
    in f [] [rhs lhs];

    mkCatDefType = mkOptionType: subtype: mkOptionType {
      name = "catDef";
      description = "a function representing categoryDefinitions or packageDefinitions for nixCats";
      descriptionClass = "noun";
      check = v: isFunction v;
      merge = loc: defs: let
        values = map (v: v.value) defs;
        mergefunc = if subtype == "replace"
        then lib.recUpdateHandleInlineORdrv 
        else if subtype == "merge"
        then lib.recursiveUpdateWithMerge
        else throw "invalid catDef subtype";
      in
      arg: foldl' mergefunc {} (map (v: v arg) values);
    };

    # all of the following can be removed when utils.catsWithDefault is removed

    filterAttrsRecursive =
      pred:
      set:
      listToAttrs (
        concatMap (name:
          let v = set.${name}; in
          if pred name v then [
            (lib.nameValuePair name (
              if isAttrs v then lib.filterAttrsRecursive pred v
              else v
            ))
          ] else []
        ) (attrNames set)
      );

    attrByPath =
      attrPath:
      default:
      set:
      let
        lenAttrPath = length attrPath;
        attrByPath' = n: s: (
          if n == lenAttrPath then s
          else (
            let
              attr = elemAt attrPath n;
            in
            if s ? ${attr} then attrByPath' (n + 1) s.${attr}
            else default
          )
        );
      in
        attrByPath' 0 set;

    setAttrByPath =
      attrPath:
      value:
      let
        len = length attrPath;
        atDepth = n:
          if n == len
          then value
          else { ${elemAt attrPath n} = atDepth (n + 1); };
      in atDepth 0;

    mapAttrsRecursiveCond =
      cond:
      f:
      set:
      let
        recurse = path:
          mapAttrs
            (name: value:
              if isAttrs value && cond value
              then recurse (path ++ [ name ]) value
              else f (path ++ [ name ]) value);
      in
      recurse [ ] set;
  };
}

