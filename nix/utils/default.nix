# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
with builtins; rec {

  # These are to be exported in flake outputs
  utils = {

    # The big function that does everything
    baseBuilder = import ../builder;

    templates = import ../templates;

    # allows for inputs named plugins-something to be turned into plugins automatically
    standardPluginOverlay = import ./standardPluginOverlay.nix;

    # makes a default package and then one for each name in packageDefinitions
    mkPackages = finalBuilder: packageDefinitions: defaultName:
      { default = finalBuilder defaultName; }
      // utils.mkExtraPackages finalBuilder packageDefinitions;

    mkExtraPackages = finalBuilder: packageDefinitions:
    (mapAttrs (name: _: finalBuilder name) packageDefinitions);

    # makes an overlay you can add to allow importing as pkgs.packageName
    # and also a default overlay similarly to above but for overlays.
    mkOverlays = finalBuilder: packageDefinitions: defaultName:
      (utils.mkDefaultOverlay finalBuilder defaultName)
      // (utils.mkExtraOverlays finalBuilder packageDefinitions);

    # I may as well make these separate functions.
    mkDefaultOverlay = finalBuilder: defaultName:
      { default = (self: super: { ${defaultName} = finalBuilder defaultName; }); };

    mkExtraOverlays = finalBuilder: packageDefinitions:
      (mapAttrs (name: (self: super: { ${name} = finalBuilder name; })) packageDefinitions);

    # maybe you want multiple nvim packages in the same system and want
    # to add them like pkgs.MyNeovims.packageName when you install them?
    # both to keep it organized and also to not have to worry about naming conflicts with programs?
    mkMultiOverlay = finalBuilder: importName: namesIncList:
      (self: super: {
        ${importName} = listToAttrs (
          map
            (name:
              {
                inherit name;
                value = finalBuilder name;
              }
            ) namesIncList
          );
        }
      );

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


    mkNixosModules = {
      dependencyOverlays
      , luaPath ? ""
      , keepLuaBuilder ? null
      , categoryDefinitions
      , packageDefinitions
      , defaultPackageName
      , ... }:
      (import ./nixosModule.nix {
        oldDependencyOverlays = dependencyOverlays;
        inherit luaPath keepLuaBuilder categoryDefinitions
          packageDefinitions defaultPackageName utils;
      });

    mkHomeModules = {
      dependencyOverlays
      , luaPath ? ""
      , keepLuaBuilder ? null
      , categoryDefinitions
      , packageDefinitions
      , defaultPackageName
      , ... }:
      (import ./homeManagerModule.nix {
        oldDependencyOverlays = dependencyOverlays;
        inherit luaPath keepLuaBuilder categoryDefinitions
          packageDefinitions defaultPackageName utils;
      });

  };

# The following are part of the builder and do not need to be separately exported.

# NIX CATS SECTION:

  # 2 recursive functions that rely on each other to
  # convert nix attrsets and lists to Lua tables and lists of strings, 
  # while literally translating booleans and null
  luaTablePrinter = attrSet: let
    luatableformatter = attrSet: let
      nameandstringmap = mapAttrs (n: value: let
          name = ''[ [[${n}]] ]'';
        in
        if value == true then "${name} = true"
        else if value == false then "${name} = false"
        else if value == null then "${name} = nil"
        else if lib.isDerivation value then "${name} = [[${value}]]"
        else if isList value then "${name} = ${luaListPrinter value}"
        else if isAttrs value then "${name} = ${luaTablePrinter value}"
        else "${name} = [[${toString value}]]"
      ) attrSet;
      resultList = attrValues nameandstringmap;
      resultString = concatStringsSep ", " resultList;
    in
    resultString;
    catset = luatableformatter attrSet;
    LuaTable = "{ " + catset + " }";
  in
  LuaTable;

  luaListPrinter = theList: let
    lualistformatter = theList: let
      stringlist = map (value:
        if value == true then "true"
        else if value == false then "false"
        else if value == null then "nil"
        else if lib.isDerivation value then "[[${value}]]"
        else if isList value then "${luaListPrinter value}"
        else if isAttrs value then "${luaTablePrinter value}"
        else "[[${toString value}]]"
      ) theList;
      resultString = concatStringsSep ", " stringlist;
    in
    resultString;
    catlist = lualistformatter theList;
    LuaList = "{ " + catlist + " }";
  in
  LuaList;


# NEOVIM BUILDER SECTION:

  # returns a flattened list with only those lists 
  # whose name was associated with a true value within the categories set
  filterAndFlatten = categories: categoryDefs:
    flattenToList (RecFilterCats categories categoryDefs);

  filterAndFlattenMapInnerAttrs = categories: twoArgFunc: categoryDefs:
    flattenAttrMapLeaves twoArgFunc (RecFilterCats categories categoryDefs);

  filterAndFlattenMapInner = categories: oneArgFunc: SetOfCategoryLists:
    map oneArgFunc (filterAndFlatten categories SetOfCategoryLists);

  RecFilterForTrue = categories: let 
    filterIt = attr: (lib.filterAttrs (name: value:
        if isBool value
        then value
        else if isAttrs value && !lib.isDerivation value
        then true
        else false
      ) attr);
    mapper = cats: mapAttrs (name: value:
        if isBool value then value else mapper (filterIt value)
      ) (filterIt cats);
  in
  mapper categories;

  # Overlays values in place of filtered true values from above
  RecFilterCats = categories: categoryDefs: let
    mapper = subCats: defAttrs: mapAttrs 
        (name: value: let
          newDefAttr = getAttr name defAttrs;
        in
        if !(isAttrs value && isAttrs newDefAttr) || lib.isDerivation newDefAttr
        then newDefAttr
        else mapper value newDefAttr)
      (intersectAttrs defAttrs subCats);
  in
  mapper (RecFilterForTrue categories) categoryDefs;

  flattenToList = attrset: concatMap
    (v:
      if isAttrs v && !lib.isDerivation v then flattenToList v else
      (if isList v then v else [v])
    ) (attrValues attrset);

  flattenAttrMapLeaves = twoArgFunc: attrset: let
    mapAttrValues = attr: attrValues (mapAttrs (name: value:
        if (isList value || isAttrs value)
        then value
        else (twoArgFunc name value)
      ) attr);
    flatten = attr: concatMap (v:
        if isAttrs v && !lib.isDerivation v then flatten v else
        (if isList v then v else [v])
      ) (mapAttrValues attr);
  in
  flatten attrset;

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

    filterAttrs = pred: set:
      listToAttrs (concatMap 
        (name: let value = set.${name}; in
          if pred name value then
          [({ inherit name value; })]
          else []
        ) (attrNames set));

  };
}

