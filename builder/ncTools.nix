# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
{ lib, writeText, nclib, ... }: with builtins; rec {
# NIX CATS INTERNAL UTILS:

  # ../utils/lib.nix
  inherit nclib;

  # writes the generated lua files for the nixCats plugin
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

  # returns [ { path, value } ... ]
  recFilterCats = implicit_defaults: categories: let
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

  # populates :NixCats petShop
  getCatSpace = let
    recursiveUpdatePickDeeper = nclib.pickyRecUpdateUntil {
      pick = path: left: right: if nclib.ncIsAttrs left then left else right;
    };
    # get the names of the categories but not the values, to avoid evaluating anything.
    mapfunc = path: mapAttrs (name: value:
      if nclib.ncIsAttrs value
      then mapfunc (path ++ [ name ]) value
      else path ++ [ name ]);

  in lib.flip lib.pipe [
    attrValues
    (map (mapfunc []))
    (foldl' recursiveUpdatePickDeeper {})
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
