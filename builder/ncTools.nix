# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
{ lib, writeText, ... }: with builtins; rec {
# NIX CATS INTERNAL UTILS:

  inherit (import ../utils/n2l.nix) toLua types;

  mkLuaFileWithMeta = modname: table: writeText "${modname}.lua" /*lua*/ ''
  local ${modname} = ${toLua table};
  return setmetatable(${modname}, {
    __call = function(self, attrpath)
      local strtable = {}
      if type(attrpath) == "table" then
          strtable = attrpath
      elseif type(attrpath) == "string" then
          for key in attrpath:gmatch("([^%.]+)") do
              table.insert(strtable, key)
          end
      else
          print('function requires a { "list", "of", "strings" } or a "dot.separated.string"')
          return
      end
      if #strtable == 0 then return nil end
      local tbl = ${modname};
      for _, key in ipairs(strtable) do
        if type(tbl) ~= "table" then return nil end
        tbl = tbl[key]
      end
      return tbl
    end
  })
  '';

  # returns a flattened list with only those lists 
  # whose name was associated with a true value within the categories set
  filterAndFlatten = categories: categoryDefs:
    flattenToList (RecFilterCats categories categoryDefs);

  filterAndFlattenMapInnerAttrs = categories: twoArgFunc: categoryDefs:
    flattenAttrMapLeaves twoArgFunc (RecFilterCats categories categoryDefs);

  filterAndFlattenMapInner = categories: oneArgFunc: SetOfCategoryLists:
    map oneArgFunc (filterAndFlatten categories SetOfCategoryLists);

  # Overlays values in place of true values in categories
  RecFilterCats = categories: categoryDefs: let
    # remove all things that are not true, or an attribute set that is not also a derivation
    filterLayer = attr: (lib.filterAttrs (name: value:
        if isBool value
        then value
        else if isAttrs value && !lib.isDerivation value
        then true
        else false
      ) attr);
    # overlay value from categoryDefs if the value in categories is true, else recurse
    mapper = subCats: defAttrs: mapAttrs 
        (name: value: let
          newDefAttr = getAttr name defAttrs;
        in
        if !(isAttrs value && isAttrs newDefAttr) || lib.isDerivation newDefAttr
        then newDefAttr
        else mapper value newDefAttr)
      (intersectAttrs defAttrs (filterLayer subCats));
  in
  mapper categories categoryDefs;

  flattenToList = attrset: concatMap
    (v:
      if isAttrs v && !lib.isDerivation v then flattenToList v
      else if isList v then v
      else if v != null then [v] else []
    ) (attrValues attrset);

  flattenAttrMapLeaves = twoArgFunc: attrset: let
    mapAttrValues = attr: attrValues (mapAttrs (name: value:
        if (isAttrs value)
        then value
        else (twoArgFunc name value)
      ) attr);
    flatten = attr: concatMap (v:
        if isAttrs v && !lib.isDerivation v then flatten v
        else if isList v then v
        else if v != null then [v] else []
      ) (mapAttrValues attr);
  in
  flatten attrset;

  getCatSpace = listOfSections: let
    recursiveUpdatePickDeeper = lhs: rhs: let
      isNonDrvSet = v: isAttrs v && !lib.isDerivation v;
      pred = path: lh: rh: ! isNonDrvSet lh || ! isNonDrvSet rh;
      picker = left: right: if isNonDrvSet left then left else right;
    in recUpUntilWpicker { inherit pred picker; } lhs rhs;
    # get the names of the categories but not the values, to avoid evaluating anything.
    mapfunc = path: mapAttrs (name: value: if isAttrs value && ! lib.isDerivation value then mapfunc (path ++ [ name ]) value else path ++ [ name ]);
    mapped = map (mapfunc []) listOfSections;
  in
  foldl' recursiveUpdatePickDeeper { } mapped;

  applyExtraCats = packageCats: extraCats: let
    recursiveUpdatePickShallower = recUpUntilWpicker {
      picker = left: right: if ! isAttrs left then left else right; };

    applyExtraCatsInternal = prev: xtracats: pkgcats: let
      filteredCatPaths = filterAndFlatten pkgcats xtracats;
      # remove if already included
      checkPath = atpath: if atpath == [] then true
        else if lib.attrByPath atpath null pkgcats == true
        then false
        else checkPath (lib.init atpath);
      filtered = lib.unique (filter (v: checkPath v) filteredCatPaths);
      toMerge = map (v: lib.setAttrByPath v true) filtered;
      firstRes = foldl' recursiveUpdatePickShallower {} (toMerge ++ [ pkgcats ]);
      # recurse until it doesnt change, so that values applying
      # to the newly enabled categories can have an effect.
    in if firstRes == prev then firstRes
      else applyExtraCatsInternal firstRes xtracats firstRes;

  in if extraCats == {} then packageCats
    else applyExtraCatsInternal packageCats extraCats packageCats;

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

}
