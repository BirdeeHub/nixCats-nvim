# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
with builtins; let
  pipe = foldl' (x: f: f x);
  genStr = str: num: concatStringsSep "" (genList (_: str) num);
  luaEnclose = str: pipe str [
    (split "(\\[=*\\[)|(]=*])")
    (concatMap (x: if isList x then x else []))
    (filter (x: x != null && x != ""))
    (map stringLength)
    (foldl' (max: x: if x > max then x else max) 0)
    (longBoiLen: longBoiLen - 2)
    (eqno: if eqno >= 0 then eqno + 1 else 0)
    (genStr "=")
    (body: "[" + body + "[" + str + "]" + body + "]")
  ];

  mkEnum = id: proto: let
    filterAttrs = pred: set:
      removeAttrs set (filter (name: ! pred name set.${name}) (attrNames set));
    mkBaseT = expr: { __type = id; inherit expr; };
    mkmk = n: p: v: mkBaseT ((p.fields or {}) // { type = n; } // ((p.default or (o: o)) v));
    types = mapAttrs (n: p: p // { name = n; mk = mkmk n p;
        check = v: typeof v == n && (p.check or (_:true)) v == true;
      }) proto;
    default_subtype = let
      defvals = attrNames (filterAttrs (n: x: isFunction (x.default or false)) proto);
      valdef = if length defvals  == 1 then head defvals
        else if defvals == [] then throw "no default type specified"
        else throw "multiple default types specified";
      in valdef;
    member = v: v.__type or null == id && v ? expr
      && null != types."${v.expr.type or default_subtype}".name or null;
    typeof = v: if ! (member v) then null
      else types."${v.expr.type or default_subtype}".name;
    resolve = v: let vt = typeof v; checkres = (proto."${vt}".check or (_: true)) v; in
      if vt == null then throw "unable to resolve, not subtype of ${id}"
      else if checkres == true then (proto."${vt}".format or (o: o.expr)) v
      else throw "unable to resolve, value is not a valid instance of type ${id}.${vt}.\nError: ${checkres}";
  in { inherit types typeof member resolve mkBaseT id default_subtype; };

  LIproto = let
    inlinecheck = v: if isString (v.expr.body or null)
      then true else "body attribute must be a string";
    funccheck = v: if ! isString (v.expr.body or null)
      then "body attribute must be a string"
      else if ! isList (v.expr.args or null)
        || any (val: ! isString val || builtins.match ''^([A-Za-z_][A-Za-z0-9_]*|\.\.\.)$'' val == null) v.expr.args
      then "args attribute must be a list of strings containing valid lua identifier names"
      else true;
  in {
    inline-safe = {
      default = (v: if v ? body then v else { body = v; });
      fields = { body = "nil"; };
      check = inlinecheck;
      format = LI: "(assert(loadstring(${luaEnclose "return ${LI.expr.body or "nil"}"}))())";
    };
    inline-unsafe = {
      fields = { body = "nil"; };
      check = inlinecheck;
      format = LI: "${LI.expr.body or "nil"}";
    };
    function-safe = {
      fields = { body = "return nil"; args = []; };
      check = funccheck;
      format = LI:
        ''(assert(loadstring(${luaEnclose ''return (function(${concatStringsSep ", " (LI.expr.args or [])}) ${LI.expr.body or "return nil"} end)''}))())'';
    };
    function-unsafe = {
      fields = { body = "return nil"; args = []; };
      check = funccheck;
      format = LI: ''(function(${concatStringsSep ", " (LI.expr.args or [])}) ${LI.expr.body or "return nil"} end)'';
    };
    with-meta = {
      fields = {
        table = {};
        meta = {};
        newtable = null; # <- if you want to specify a different first arg to setmetatable
        tablevar = "tbl_in"; # <- varname to refer to the table, to avoid translating multiple times
      };
      check = v:
        if ! isAttrs (v.expr.table or null) || ! isAttrs (v.expr.meta or null) then 
          "both 'table' and 'meta' attributes are required and must be tables"
        else if ! isString (v.expr.tablevar or null)
          || builtins.match ''^([A-Za-z_][A-Za-z0-9_]*|\.\.\.)$'' v.expr.tablevar == null then 
          "'tablevar' must be a valid lua identifier name"
        else 
          true;
      format = LI: opts: let
        metaarg1 = if LI.expr.newtable or null == null then LI.expr.tablevar or "{}" else toLuaFull opts LI.expr.newtable;
        result = inline.types.function-unsafe.mk {
          args = [ (LI.expr.tablevar or "tbl_in") ];
          body = ''return setmetatable(${metaarg1}, ${toLuaFull opts LI.expr.meta})'';
        };
      in "(${toLuaFull opts result}(${toLuaFull opts LI.expr.table}))";
    };
  };

  inline = mkEnum "nix-to-lua-inline" LIproto;

  toLuaFull = {
    pretty ? true,
    indentSize ? 2,
    # adds indenting to multiline strings
    # and multiline lua expressions
    formatstrings ? false, # <-- only active if pretty is true
    _level ? 0, # <- starting indentation level, for internal use when defining inline types
    ...
  }@opts: input: let
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
      else if inline.member value then let
          res = inline.resolve value;
        in if isFunction res then res (opts // { _level = level; }) else replacer res
      else if value ? outPath then luaEnclose "${value.outPath}"
      else if isDerivation value then luaEnclose "${value}"
      else if isAttrs value then "${luaTablePrinter level value}"
      else if isFunction value then addErrorContext ("nixCats.utils.n2l.toLua called on a function with these functionArgs: " + (toJSON (functionArgs value)))
        (throw "Lua cannot run nix functions. Either call your function first, or make a lua function using `utils.n2l.types.function-safe.mk`.")
      else replacer (luaEnclose (toString value));

    luaTablePrinter = level: set: pipe set [
      (mapAttrs (n: v: "[ ${luaEnclose "${n}"} ] = ${doSingleLuaValue (level + 1) v}"))
      attrValues
      (concatStringsSep ",${nl_spc (level + 1)}")
      (str: "{${nl_spc (level + 1)}" + str + "${nl_spc level}}")
    ];

    luaListPrinter = level: list: pipe list [
      (map (doSingleLuaValue (level + 1)))
      (concatStringsSep ",${nl_spc (level + 1)}")
      (str: "{${nl_spc (level + 1)}" + str + "${nl_spc level}}")
    ];

  in
  doSingleLuaValue _level input;

in {

  toLua = toLuaFull {};

  prettyLua = toLuaFull { pretty = true; formatstrings = true; };

  uglyLua = toLuaFull { pretty = false; formatstrings = false; };

  inherit mkEnum inline toLuaFull;
  inherit (inline) types typeof member default_subtype;

  resolve = value: let res = inline.resolve value; in
    if isFunction res then (res { pretty = false; }) else res;

}
