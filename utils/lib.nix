with builtins; rec {
  mkCatDefType = mkOptionType: subtype: mkOptionType {
    name = "catDef";
    description = "a function representing categoryDefinitions or packageDefinitions for nixCats";
    descriptionClass = "noun";
    check = v: isFunction v;
    merge = loc: defs: let
      values = map (v: v.value) defs;
      mergefunc = if subtype == "replace"
      then recUpdateHandleInlineORdrv 
      else if subtype == "merge"
      then recursiveUpdateWithMerge
      else throw "invalid catDef subtype";
    in
    arg: foldl' mergefunc {} (map (v: v arg) values);
  };

  n2l = import ./n2l.nix;

  isDerivation = value: value.type or null == "derivation";

  updateUntilPred = path: lhs: rhs:
    isDerivation lhs || isDerivation rhs
    || n2l.member lhs || n2l.member rhs
    || ! isAttrs lhs || ! isAttrs rhs;

  recursiveUpdateUntilDRV = recUpUntilWpicker { pred = path: lhs: rhs:
    isDerivation lhs || isDerivation rhs || ! isAttrs lhs || ! isAttrs rhs; };

  recUpdateHandleInlineORdrv = recUpUntilWpicker { pred = updateUntilPred; };

  unique = foldl' (acc: e: if elem e acc then acc else acc ++ [ e ]) [];

  recursiveUpdateWithMerge = recUpUntilWpicker {
    pred = updateUntilPred;
    picker = left: right:
      if isList left && isList right
        then unique (left ++ right)
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
    listToAttrs (map (n: nameValuePair n (f n)) names);

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


  # DEPRECATED
  catsWithDefault = categories: attrpath: defaults: subcategories: let
    filterAttrsRecursive =
      pred:
      set:
      listToAttrs (
        concatMap (name:
          let v = set.${name}; in
          if pred name v then [
            (nameValuePair name (
              if isAttrs v then filterAttrsRecursive pred v
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


    include_path = let
      flattener = cats: let
        mapper = attrs: map (v: if isAttrs v then mapper v else v) (attrValues attrs);
        flatten = accum: LoLoS: foldl' (acc: v: if any (i: isList i) v then flatten acc v else acc ++ [ v ]) accum LoLoS;
      in flatten [] (mapper cats);

      mapToSetOfPaths = cats: let
        removeNullPaths = attrs: filterAttrsRecursive (n: v: v != null) attrs;
        mapToPaths = attrs: mapAttrsRecursiveCond (as: ! isDerivation as) (path: v: if v == true then path else null) attrs;
      in removeNullPaths (mapToPaths cats);

      result = let
        final_cats = attrByPath attrpath false categories;
        allIncPaths = flattener (mapToSetOfPaths final_cats);
      in if isAttrs final_cats && ! isDerivation final_cats && allIncPaths != []
        then head allIncPaths
        else []; 
    in
    result;

    toMerge = let
      firstGet = if isAttrs subcategories && ! isDerivation subcategories
        then attrByPath include_path [] subcategories
        else if isList subcategories then subcategories else [ subcategories ];

      fIncPath = if isAttrs firstGet && ! isDerivation firstGet
        then include_path ++ [ "default" ] else include_path;

      normed = let
        listType = if isAttrs firstGet && ! isDerivation firstGet
          then attrByPath fIncPath [] subcategories
          else if isList firstGet then firstGet else [ firstGet ];
        attrType = let
          pre = if isAttrs firstGet && ! isDerivation firstGet
            then attrByPath fIncPath {} subcategories
            else firstGet;
          basename = if fIncPath != [] then tail fIncPath else "default";
          fin = if isAttrs pre && ! isDerivation pre then pre else { ${basename} = pre; };
        in
        fin;
      in
      if isList defaults then listType else if isAttrs defaults then attrType else throw "defaults must be a list or a set";

      final = setAttrByPath fIncPath (if isList defaults then normed ++ defaults else { inherit normed; default = defaults; });
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
  if isAttrs subcategories && ! isDerivation subcategories then
    recUpdateHandleInlineORdrv subcategories toMerge
  else toMerge;

}
