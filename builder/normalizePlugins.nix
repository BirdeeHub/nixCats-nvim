{
  start ? [],
  opt ? [],
  lib,
}: let
  # accepts several plugin syntaxes,
  # specified in :h nixCats.flake.outputs.categoryDefinitions.scheme
  parsepluginspec = opt: p: with builtins; let
    checkAttrs = attrs: all (v: isString v) (attrValues attrs);
    typeToSet = type: cfg: if type == "viml"
      then { vim = cfg; }
      else { ${type} = cfg; };

    config = if ! (p ? plugin) then null
    else if isAttrs (p.config or null) && checkAttrs p.config
      then p.config
    else if isString (p.config or null) && isString (p.type or null)
      then typeToSet p.type p.config
    else if isString (p.config or null)
      then { vim = p.config; }
    else null;

  in {
    optional = if isBool (p.optional or null) then p.optional else opt;
    priority = if isInt (p.priority or null) then p.priority else 150;
    plugin = if p ? plugin && p ? name
      then p.plugin // { pname = p.name; }
      else p.plugin or p;
    inherit config;
  };

  inherit (import ../utils/n2l.nix) toLua;
  setToString = cfg: let
    lua = cfg.lua;
    vim = lib.optionalString (cfg ? vim) "vim.cmd(${toLua cfg.vim})";
  in ''
    ${lua}
    ${vim}
  '';
  get_and_sort = plugins: with builtins; lib.pipe plugins [
    (map (v: if isAttrs (v.config or null) then { inherit (v) config priority; } else null))
    (filter (v: v != null))
    (sort (a: b: a.priority < b.priority))
    (map (v: setToString v.config))
    lib.unique
    (concatStringsSep "\n")
  ];

  pluginsWithConfig = (map (parsepluginspec false) start) ++ (map (parsepluginspec true) opt);

in {
  plugins = map (v: { inherit (v) plugin optional; }) pluginsWithConfig;
  inlineConfigs = get_and_sort pluginsWithConfig;
}
