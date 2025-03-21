{
  startup ? [],
  optional ? [],
  lib,
  n2l,
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
    vim = lib.optionalString (cfg ? vim) "vim.cmd(${n2l.toLua cfg.vim})";
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
  start = let
    # gets plugin.dependencies from
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vim/plugins/overrides.nix
    findDependenciesRecursively = plugins: lib.concatMap transitiveClosure plugins;
    transitiveClosure = plugin:
      [ plugin ] ++ builtins.concatLists (map transitiveClosure plugin.dependencies or []);

  in lib.pipe pluginsWithConfig [
    (builtins.filter (v: ! v.optional))
    (map (st: st.plugin))
    (st: findDependenciesRecursively st ++ lib.subtractLists opt (findDependenciesRecursively opt))
  ];

  passthru_initLua = with builtins; lib.pipe (start ++ opt) [
    (map (v: v.passthru.initLua or null))
    (filter (v: v != null))
    lib.unique
    (concatStringsSep "\n")
  ];
in {
  inherit start opt passthru_initLua;
  inherit (user_plugin_configs) preInlineConfigs inlineConfigs;
}
