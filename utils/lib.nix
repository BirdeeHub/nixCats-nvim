with builtins; rec {
  mkCatDefType = mkOptionType: pkgType: subtype: let
    pkgdesc = ''function representing the settings and categories for a nvim package'';
    catdesc = ''function returning sets of categories of different types of dependency'';
    subtypedesc = ",\n where multiple declarations are combined using ${if subtype == "merge" then "utils.deepmergeCats" else "utils.mergeCatDefs"}";
  in mkOptionType {
    name = "catDef";
    description = "${if pkgType then pkgdesc else catdesc}${subtypedesc}";
    descriptionClass = "noun";
    check = v: isFunction v;
    merge = loc: defs: let
      mergefunc = if subtype == "replace"
      then recUpdateHandleInlineORdrv 
      else if subtype == "merge"
      then recursiveUpdateWithMerge
      else throw "invalid catDef subtype";
    in
    arg: pipe defs [
      (map (v: v.value arg))
      (foldl' mergefunc {})
    ];
  };

  n2l = import ./n2l.nix;

  pipe = builtins.foldl' (x: f: f x);

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
        then left ++ right
      # category lists can contain mixes of sets and derivations.
      # But they are both attrsets according to typeOf, so we dont need a check for that.
      else if isList left && all (lv: typeOf lv == typeOf right) left then
        left ++ [ right ]
      else if isList right && all (rv: typeOf rv == typeOf left) right then
        [ left ] ++ right
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

  recUpUntilWpicker = {
    pred ? (path: lh: rh: ! isAttrs lh || ! isAttrs rh),
    picker ? (l: r: r)
  }: lhs: rhs: let
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
