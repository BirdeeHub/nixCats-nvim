with builtins; let
  genStr = str: num: concatStringsSep "" (genList (_: str) num);
  luaEnclose = inString: let
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

  mkEnum = id: proto: let
    filterAttrs = pred: set:
      removeAttrs set (filter (name: ! pred name set.${name}) (attrNames set));
    mkBaseT = expr: { __type = id; inherit expr; };
    mkmk = n: p: default: v: mkBaseT ((p.fields or {}) // { type = n; } // default v);
    types = mapAttrs (n: p: p // { name = n; mk = mkmk n p (p.default or (o: o)); }) proto;
    default_subtype = let
      defvals = attrNames (filterAttrs (n: x: isFunction (x.default or false)) proto);
      valdef = if defvals == [] then throw "no default type specified"
        else if length defvals  == 1 then head defvals
        else throw "multiple default types specified";
    in valdef;
    member = v: (v.__type or null == id && v ? expr) && null != types."${v.expr.type or default_subtype}".name or null;
    typeof = v: let
      in if ! (member v) then null
      else types."${v.expr.type or default_subtype}".name;
    resolve = v: let vt = typeof v; in
      if vt == null then throw "unable to resolve, not subtype of ${id}"
      else (proto."${vt}".format or (o: o.expr)) v;
  in { inherit types typeof member resolve mkBaseT id default_subtype; };

  LIproto = let
    fixargs = LI: if any (v: ! isString v || builtins.match ''^([A-Za-z_][A-Za-z0-9_]*|\.\.\.)$'' v == null) (LI.expr.args or [])
      then throw "args must be valid lua identifiers"
      else concatStringsSep ", " (LI.expr.args or []);
  in {
    inline-safe = {
      default = (v: if v ? body then v else { body = v; });
      fields = { body = "nil"; };
      format = LI: "assert(loadstring(${luaEnclose "return ${LI.expr.body or LI.expr or "nil"}"}))()";
    };
    inline-unsafe = {
      fields = { body = "nil"; };
      format = LI: "${LI.expr.body or "nil"}";
    };
    function-safe = {
      fields = { body = "return nil"; args = []; };
      format = LI: ''(function(${fixargs (LI.expr.args or [])})
        return assert(loadstring(${luaEnclose "${LI.expr.body or "return nil"}"}))()
      end)'';
    };
    function-unsafe = {
      fields = { body = "return nil"; args = []; };
      format = LI: ''(function(${fixargs (LI.expr.args or [])})
        ${LI.expr.body or "return nil"}
      end)'';
    };
  };

  inline = mkEnum "nix-to-lua-inline" LIproto;

in rec {

  toLua = toLuaFull {};

  prettyLua = toLuaFull { pretty = true; formatstrings = true; };

  uglyLua = toLuaFull { pretty = false; formatstrings = false; };

  inherit mkEnum inline;
  inherit (inline) types typeof member resolve default_subtype;

  toLuaFull = {
    pretty ? true,
    indentSize ? 2,
    # adds indenting to multiline strings
    # and multiline lua expressions
    formatstrings ? false, # <-- only active if pretty is true
    ...
  }: input: let
    nl_spc = level: if pretty == true
      then "\n${genStr " " (level * indentSize)}" else " ";

    doSingleLuaValue = level: value: let
      replacer = str: if pretty && formatstrings then replaceStrings [ "\n" ] [ "${nl_spc level}" ] str else str;
      isDerivation = value: value.type or null == "derivation";
    in
      if value == true then "true"
      else if value == false then "false"
      else if value == null then "nil"
      else if isFloat value || isInt value then toString value
      else if isList value then "${luaListPrinter level value}"
      else if inline.member value then replacer (inline.resolve value)
      else if value ? outPath then luaEnclose "${value.outPath}"
      else if isDerivation value then luaEnclose "${value}"
      else if isAttrs value then "${luaTablePrinter level value}"
      else replacer (luaEnclose (toString value));

    luaTablePrinter = level: attrSet: let
      nameandstringmap = mapAttrs (n: value: let
        name = "[ " + (luaEnclose "${n}") + " ]";
      in
        "${name} = ${doSingleLuaValue (level + 1) value}") attrSet;
      resultList = attrValues nameandstringmap;
      catset = concatStringsSep ",${nl_spc (level + 1)}" resultList;
      LuaTable = "{${nl_spc (level + 1)}" + catset + "${nl_spc level}}";
    in
    LuaTable;

    luaListPrinter = level: theList: let
      stringlist = map (doSingleLuaValue (level + 1)) theList;
      catlist = concatStringsSep ",${nl_spc (level + 1)}" stringlist;
      LuaList = "{${nl_spc (level + 1)}" + catlist + "${nl_spc level}}";
    in
    LuaList;

  in
  doSingleLuaValue 0 input;

}
