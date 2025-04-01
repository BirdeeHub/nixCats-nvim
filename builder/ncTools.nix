# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
{ lib, nclib }: with builtins; rec {
# NIX CATS INTERNAL UTILS:

  # ../utils/lib.nix
  inherit nclib;

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

  normalizePlugins = {
    startup ? [],
    optional ? [],
    autoPluginDeps ? true
  }: let
    # accepts several plugin syntaxes,
    # specified in :h nixCats.flake.outputs.categoryDefinitions.scheme
    parsepluginspec = opt: p: with builtins; let
      checkAttrs = attrs: all (v: isString v) (attrValues attrs);
      typeToSet = type: cfg: if type == "viml"
        then { vim = cfg; }
        else { ${type} = cfg; };
    in {
      config = if ! (p ? plugin) then null
      else if isAttrs p.config or null && checkAttrs p.config
        then p.config
      else if isString p.config or null && isString p.type or null
        then typeToSet p.type p.config
      else if isString p.config or null
        then { vim = p.config; }
      else null;

      optional = if isBool p.optional or null
        then p.optional else opt;
      priority = if isInt p.priority or null
        then p.priority else 150;
      pre = if isBool p.pre or null
        then p.pre else false;
      plugin = if p ? plugin && p ? name
        then p.plugin // { pname = p.name; }
        else p.plugin or p;
    };

    setToString = cfg: let
      lua = cfg.lua or "";
      vim = lib.optionalString (cfg ? vim) "vim.cmd(${nclib.n2l.toLua cfg.vim})";
    in ''
      ${lua}
      ${vim}
    '';
    get_and_sort = plugins: with builtins; lib.pipe plugins [
      (map (v:
        if isAttrs v.config or null
        then { inherit (v) priority pre; cfg = setToString v.config; }
        else null
      ))
      (filter (v: v != null))
      (sort (a: b: a.priority < b.priority))
      (lib.partition (v: v.pre == true))
      ({ right ? [], wrong ? []}: let
        r_mapped = lib.unique (map (v: v.cfg) right);
        l_mapped = lib.unique (map (v: v.cfg) wrong);
      in {
        preInlineConfigs = concatStringsSep "\n" r_mapped;
        inlineConfigs = concatStringsSep "\n" (lib.subtractLists r_mapped l_mapped);
      })
    ];

    pluginsWithConfig = map (parsepluginspec false) startup ++ map (parsepluginspec true) optional;
    user_plugin_configs = get_and_sort pluginsWithConfig;

    opt = lib.pipe pluginsWithConfig [
      (builtins.filter (v: v.optional))
      (map (v: v.plugin))
    ];
    start = with builtins; let
      # gets plugin.dependencies from
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vim/plugins/overrides.nix
      findDependenciesRecursively = plugins: lib.concatMap transitiveClosure plugins;
      transitiveClosure = plugin:
        [ plugin ] ++ concatLists (map transitiveClosure plugin.dependencies or []);
      subtractByName = tosub: filter (v: all (x: lib.getName v != lib.getName x) tosub);

      st1 = lib.pipe pluginsWithConfig [
        (filter (v: ! v.optional))
        (map (st: st.plugin))
      ];

    in if autoPluginDeps then lib.pipe st1 [
      (st: findDependenciesRecursively st ++ findDependenciesRecursively opt)
      (subtractByName (opt ++ st1))
      (st: st1 ++ st)
    ] else st1;

    passthru_initLua = with builtins; lib.pipe (start ++ opt) [
      (map (v: v.passthru.initLua or null))
      (filter (v: v != null))
      lib.unique
      (concatStringsSep "\n")
    ];
  in {
    inherit start opt passthru_initLua;
    inherit (user_plugin_configs) preInlineConfigs inlineConfigs;
  };

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
