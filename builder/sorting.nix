# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
{ lib, nclib }: with builtins; rec {
# NIX CATS INTERNAL UTILS:

  # returns a flattened list with only those lists 
  # whose name was associated with a true value within the categories set
  # these 2 functions and recFilterCats below are the functions
  # that do the sorting for the nixCats category scheme
  filterAndFlatten = categories: lib.flip lib.pipe [
    (recFilterCats true categories) # <- returns [ { path, value } ... ]
    (concatMap (v: if isList v.value then v.value else if v.value != null then [v.value] else []))
  ];

  filterAndFlattenMapInnerAttrs = categories: twoArgFunc: lib.flip lib.pipe [
    (recFilterCats true categories) # <- returns [ { path, value } ... ]
    (map (v: twoArgFunc (lib.last v.path) v.value))
    (concatMap (v: if isList v then v else if v != null then [v] else []))
  ];

  # destructures attrs recursively, returns [ { path, value } ... ]
  recAttrsToList = here: lib.flip lib.pipe [
    (lib.mapAttrsToList (name: value: {
      path = here ++ [name];
      inherit value;
    }))
    (foldl' (a: v: if nclib.ncIsAttrs v.value
      then a ++ recAttrsToList v.path v.value
      else a ++ [v]
    ) [])
  ];

  # returns [ { path, value } ... ]
  recFilterCats = implicit_defaults: categories: let
    # check paths of included cats only
    catlist = lib.pipe categories [
      (recAttrsToList [])
      (filter (v: v.value == true))
      (map (v: v.path))
    ];
    # check if each is enabled
    cond = def: any (cat: lib.take (length cat) def.path == cat) catlist
      || implicit_defaults && any (cat: lib.take (length def.path) cat == def.path) catlist;
  # destructure category definition and filter based on cond
  in lib.flip lib.pipe [
    (recAttrsToList [])
    (filter cond)
  ];

  combineCatsOfFuncs = categories: secname: section:
    x: lib.pipe section [
      (filterAndFlatten categories)
      (map (value:
        if x == null && lib.isFunction value then (import ./errors.nix).catsOfFn secname
        else if lib.isFunction value then value x else value
      ))
      lib.flatten
      lib.unique
    ];

  filterAndFlattenEnvVars = categories: secname:
    lib.flip lib.pipe [
      (filterAndFlattenMapInnerAttrs categories (name: value:
        if lib.isFunction value || isList value
        then (import ./errors.nix).envVar secname
        else [ [ "--set" name value ] ]
      ))
      lib.unique
      concatLists
    ];

  filterAndFlattenWrapArgs = categories: secname: let
    checker = _: value: if isList value && (all (v: isList (v.value or v)) value || all (v: isString v) value)
      then value else (import ./errors.nix).wrapArgs secname;
  in lib.flip lib.pipe [
      (filterAndFlattenMapInnerAttrs categories checker)
      lib.flatten
      (sort (a: b: a.priority or 150 < b.priority or 150))
      (map (v: v.value or v))
      concatLists
    ];

  # also sorts bashBeforeWrapper
  filterAndFlattenXtraWrapArgs = categories: secname: lib.flip lib.pipe [
    (filterAndFlatten categories)
    (sort (a: b: a.priority or 150 < b.priority or 150))
    (map (v: if nclib.ncIsAttrs v then v.value or ((import ./errors.nix).xtraWrapArgs secname) else v))
  ];

  # populates :NixCats petShop
  getCatSpace = { categories, sections, final_cat_defs_set }: let
    toScan = lib.pipe sections [
      (map (sec: { inherit sec; val = lib.attrByPath sec null final_cat_defs_set; }))
      (filter (v: nclib.ncIsAttrs v.val))
    ];
    allenabled = map (v: {
      inherit (v) sec;
      val = lib.pipe v.val [
        (recFilterCats true categories)
        (map (val: val.path))
      ];
    }) toScan;
  in lib.pipe toScan [
    (map (v: { inherit (v) sec; has = lib.pipe v.val [
      (recAttrsToList [])
      (map (val: val.path))
    ]; }))
    (map (v: v // {
      enabled = (lib.findFirst (val: v.sec == val.sec) (throw "This error will never be returned") allenabled).val;
    }))
    (map (v: { inherit (v) sec; val = lib.pipe v.has [
      (map (val: lib.setAttrByPath val (elem val v.enabled)))
      (foldl' lib.recursiveUpdate {})
    ]; }))
    (filter (v: v.val != {}))
    (map (v: lib.setAttrByPath v.sec v.val))
    (foldl' lib.recursiveUpdate {})
  ];

  # controls extraCats in categoryDefinitions
  applyExtraCats = categories: extraCats: if extraCats == {} then categories else let
    filterAndFlattenNoDefaults = categories: lib.flip lib.pipe [
      (recFilterCats false categories) # <- returns [ { path, value } ... ]
      (concatMap (v: if isList v.value then v.value else if v.value != null then [v.value] else []))
    ];
    # true if any containing or sub category is enabled
    condcheck = prev: lib.flip lib.pipe [
      (atp: if isList atp then atp else (import ./errors.nix).extraCats)
      (atp: lib.setAttrByPath atp true)
      (filterAndFlatten prev)
      (v: v != [])
    ];
    # true if any containing category is enabled
    whencheck = prev: lib.flip lib.pipe [
      (atp: if isList atp then atp else (import ./errors.nix).extraCats)
      (atp: lib.setAttrByPath atp true)
      (filterAndFlattenNoDefaults prev)
      (v: v != [])
    ];
    recursiveUpdatePickShallower = nclib.pickyRecUpdateUntil {
      pick = path: left: right: if ! nclib.ncIsAttrs left then left else right;
    };
    applyExtraCatsInternal = prev: let
      checkPath = item: if isList item then true else lib.pipe item [
        (spec: map (condcheck prev) (spec.cond or []) ++ map (whencheck prev) (spec.when or []))
        (foldl' (acc: v: if acc then v else false) true) # <- defaults to true if no conditions for specs specified
        (enabled: enabled && (if isList (item.cat or null) then true else (import ./errors.nix).extraCats))
      ];
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
  # if extraCats wasn't empty, start applying!
  in applyExtraCatsInternal categories;

}
