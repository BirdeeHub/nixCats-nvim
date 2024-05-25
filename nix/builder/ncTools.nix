with builtins; rec {
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

  # https://github.com/NixOS/nixpkgs/blob/nixos-23.05/lib/attrsets.nix
  lib = {
    isDerivation = value: value.type or null == "derivation";

    filterAttrs = pred: set:
      listToAttrs (concatMap 
        (name: let value = set.${name}; in
          if pred name value then
          [({ inherit name value; })]
          else []
        ) (attrNames set));

  };
}
