# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
{ lib, writeText, nclib, ... }: with builtins; rec {
# NIX CATS INTERNAL UTILS:

  inherit nclib;

  mkLuaFileWithMeta = filename: table: writeText filename /*lua*/ ''
  return setmetatable(${nclib.n2l.toLua table}, {
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
      local tbl = self;
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

  # Overlays values in place of true values in categories
  RecFilterCats = categories: categoryDefs: let
    # remove all things that are not true, or an attribute set that is not also a derivation
    filterLayer = lib.filterAttrs (name: value:
        if isBool value
        then value
        else if isAttrs value && !lib.isDerivation value
        then true
        else false
      );
    # overlay value from categoryDefs if the value in categories is true, else recurse
    mapper = subCats: defAttrs: let
      mapfunc = name: value: let
          newDefAttr = getAttr name defAttrs;
        in
        if !(isAttrs value && isAttrs newDefAttr) || lib.isDerivation newDefAttr
        then newDefAttr
        else mapper value newDefAttr;
    in lib.pipe subCats [
      filterLayer
      (intersectAttrs defAttrs)
      (mapAttrs mapfunc)
    ];
  in
  mapper categories categoryDefs;

  flattenToList = attrset: concatMap
    (v:
      if isAttrs v && !lib.isDerivation v then flattenToList v
      else if isList v then v
      else if v != null then [v] else []
    ) (attrValues attrset);

  flattenAttrMapLeaves = twoArgFunc: attrset: let
    mapAttrValues = lib.mapAttrsToList (name: value:
        if isAttrs value && !lib.isDerivation value
        then value
        else (twoArgFunc name value)
      );
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
    in nclib.recUpUntilWpicker { inherit pred picker; } lhs rhs;
    # get the names of the categories but not the values, to avoid evaluating anything.
    mapfunc = path: mapAttrs (name: value:
      if isAttrs value && ! lib.isDerivation value
      then mapfunc (path ++ [ name ]) value
      else path ++ [ name ]);

  in lib.pipe listOfSections [
    (map (mapfunc []))
    (foldl' recursiveUpdatePickDeeper {})
  ];

  applyExtraCats = categories: extraCats: if extraCats == {} then categories else let
    errormsg = ''
      # ERROR: incorrect extraCats syntax in categoryDefinitions:
      # USAGE:
      extraCats = {
        target.cat = [ # <- categories must be a list of (sets or list of strings)
          [ "to" "enable" ]
          {
            cat = [ "other" "toenable" ]; #<- required if providing the set form
            # enable cat only if all in cond are enabled
            cond = [
              [ "other" "category" ] # <- cond must be a list of list of strings
            ];
          }
        ];
      };
    '';

    recursiveUpdatePickShallower = nclib.recUpUntilWpicker {
      picker = left: right: if ! isAttrs left then left else right; };

    applyExtraCatsInternal = prev: let
      checkPath = item: if isList item then true
        # checks if all in spec.cond are enabled, if so,
        # it returns true if spec.cat is valid
        else lib.pipe (item.cond or []) (let
          # true if enabled by categories
          condcheck = atpath: lib.pipe atpath [
            (atp: if isList atp then atp else throw errormsg)
            (atp: lib.setAttrByPath atp true)
            (filterAndFlatten prev)
            (v: v != [])
          ];
        in [
          (map condcheck)
          (foldl' (acc: v: if acc then v else false) true) # <- defaults to true if no cond specified
          (enabled: enabled && (if isList (item.cat or null) then true else throw errormsg))
        ]);

      nextCats = lib.pipe extraCats [
        (filterAndFlatten prev)
        lib.unique
        (filter checkPath)
        (map (v: lib.setAttrByPath (v.cat or v) true))
        (v: v ++ [ prev ])
        (foldl' recursiveUpdatePickShallower {})
      ];
      # recurse until it doesnt change, so that values applying
      # to the newly enabled categories can have an effect.
    in if nextCats == prev then nextCats
      else applyExtraCatsInternal nextCats;

  in applyExtraCatsInternal categories;

}
