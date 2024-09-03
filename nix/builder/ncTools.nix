with builtins; rec {
# NIX CATS SECTION:
  
  mkLuaInline = expr: { __type = "nix-to-lua-inline"; inherit expr; };

  toLua = toLuaInternal {};

  toLuaInternal = {
    pretty ? true,
    # adds indenting to multiline strings
    # and multiline lua expressions
    formatstrings ? false, # <-- only active if pretty is true
    ...
  }: input: let

    isLuaInline = toCheck:
    if isAttrs toCheck && toCheck ? __type
    then toCheck.__type == "nix-to-lua-inline"
    else false;

    luaToString = LI: "assert(loadstring(${luaEnclose "return ${LI.expr}"}))()";

    luaEnclose = inString: let
      genStr = str: num: concatStringsSep "" (genList (_: str) num);

      measureLongBois = inString: let
        normalize_split = list: filter (x: x != null && x != "")
            (concatMap (x: if isList x then x else [ ]) list);
        splitter = str: normalize_split (split "(\\[=*\\[)|(]=*])" str);
        counter = str: map stringLength (splitter str);
        getMax = str: foldl' (max: x: if x > max then x else max) 0 (counter str);
        getEqSigns = str: (getMax str) - 2;
        longBoiLength = getEqSigns inString;
      in
      if longBoiLength >= 0 then longBoiLength + 1 else 0;

      eqNum = measureLongBois inString;
      eqStr = genStr "=" eqNum;
      bL = "[" + eqStr + "[";
      bR = "]" + eqStr + "]";
    in
    bL + inString + bR;

    nl_spc = level: let
      genStr = str: num: concatStringsSep "" (genList (_: str) num);
    in
    if pretty == true then "\n${genStr " " (level * 2)}" else " ";

    doSingleLuaValue = level: value: let
      replacer = str: if pretty && formatstrings then builtins.replaceStrings [ "\n" ] [ "${nl_spc level}" ] str else str;
    in
      if value == true then "true"
      else if value == false then "false"
      else if value == null then "nil"
      else if isList value then "${luaListPrinter value level}"
      else if lib.isDerivation value then luaEnclose "${value}"
      else if isLuaInline value then replacer (luaToString value)
      else if isAttrs value then "${luaTablePrinter value level}"
      else replacer (luaEnclose (toString value));

    luaTablePrinter = attrSet: level: let
      luatableformatter = attrSet: let
        nameandstringmap = mapAttrs (n: value: let
            name = "[ " + (luaEnclose "${n}") + " ]";
          in
          "${name} = ${doSingleLuaValue (level + 1) value}") attrSet;
        resultList = attrValues nameandstringmap;
        resultString = concatStringsSep ",${nl_spc (level + 1)}" resultList;
      in
      resultString;
      catset = luatableformatter attrSet;
      LuaTable = "{${nl_spc (level + 1)}" + catset + "${nl_spc level}}";
    in
    LuaTable;

    luaListPrinter = theList: level: let
      lualistformatter = theList: let
        stringlist = map (doSingleLuaValue (level + 1)) theList;
        resultString = concatStringsSep ",${nl_spc (level + 1)}" stringlist;
      in
      resultString;
      catlist = lualistformatter theList;
      LuaList = "{${nl_spc (level + 1)}" + catlist + "${nl_spc level}}";
    in
    LuaList;

  in
  doSingleLuaValue 0 input;

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
