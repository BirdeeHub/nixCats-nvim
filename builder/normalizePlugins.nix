{
  pluginsOG,
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
    plugin = if p ? plugin && p ? name
      then p.plugin // { pname = p.name; }
      else p.plugin or p;
    inherit config;
  };

  genPluginList = { start ? [ ], opt ? [ ], }:
    (map (parsepluginspec false) start) ++ (map (parsepluginspec true) opt);

  pluginsWithConfig = genPluginList pluginsOG;

  getConfigsOfType = type: plugins: with builtins; lib.pipe plugins [
    (map (v: if isString (v.config.${type} or null) then v.config.${type} else null))
    (filter (v: v != null))
    lib.unique
    (concatStringsSep "\n")
  ];

in {
  plugins = map (v: { inherit (v) plugin optional; }) pluginsWithConfig;
  luaPluginConfigs = getConfigsOfType "lua" pluginsWithConfig;
  vimlPluginConfigs = getConfigsOfType "vim" pluginsWithConfig;
}
