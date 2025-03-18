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

  recursiveUpdateUntilDRV = pickyRecUpdateUntil { pred = path: lhs: rhs:
    isDerivation lhs || isDerivation rhs || ! isAttrs lhs || ! isAttrs rhs; };

  recUpdateHandleInlineORdrv = pickyRecUpdateUntil { pred = updateUntilPred; };

  recursiveUpdateWithMerge = pickyRecUpdateUntil {
    pred = updateUntilPred;
    pick = path: left: right:
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

  pickyRecUpdateUntil = {
    pred ? (path: lh: rh: ! isAttrs lh || ! isAttrs rh),
    pick ? (path: l: r: r)
  }: lhs: rhs: let
    f = attrPath:
      zipAttrsWith (n: values:
        let here = attrPath ++ [n]; in
        if length values == 1 then
          head values
        else if pred here (elemAt values 1) (head values) then
          pick here (elemAt values 1) (head values)
        else
          f here values
      );
  in f [] [rhs lhs];

  functionArgs = f:
    if f ? __functor
    then f.__functionArgs or (functionArgs (f.__functor f))
    else builtins.functionArgs f;
  setFunctionArgs = f: args:
    {
      __functor = self: f;
      __functionArgs = args;
    };
  mirrorFunctionArgs = f: let
    fArgs = functionArgs f;
  in
  g: setFunctionArgs g fArgs;

  # modified to add an extra overrideNixCats value that
  # works the same as override but wont be shadowed by callPackage
  makeOverridable = overrideDerivation:
    f:
    let
      mkOver = makeOverridable overrideDerivation;
      # Creates a functor with the same arguments as f
      mirrorArgs = mirrorFunctionArgs f;
    in
    mirrorArgs (
      origArgs:
      let
        result = f origArgs;

        # Changes the original arguments with (potentially a function that returns) a set of new attributes
        overrideWith = newArgs: origArgs // (if isFunction newArgs then newArgs origArgs else newArgs);

        # Re-call the function but with different arguments
        overrideArgs = mirrorArgs (newArgs: mkOver f (overrideWith newArgs));
        # Change the result of the function call by applying g to it
        overrideResult = g: mkOver (mirrorArgs (args: g (f args))) origArgs;
      in
      if isAttrs result then
        result
        // {
          override = overrideArgs;
          overrideNixCats = overrideArgs;
          overrideDerivation = fdrv: overrideResult (x: overrideDerivation x fdrv);
          ${if result ? overrideAttrs then "overrideAttrs" else null} =
            fdrv: overrideResult (x: x.overrideAttrs fdrv);
        }
      else if isFunction result then
        # Transform the result into a functor while propagating its arguments
        setFunctionArgs result (functionArgs result)
        // {
          override = overrideArgs;
          overrideNixCats = overrideArgs;
        }
      else
        result
    );

}
