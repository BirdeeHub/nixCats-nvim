{
  pluginsOG,
  lib,
}: let
  # accepts 4 different plugin syntaxes, specified in :h nixCats.flake.outputs.categoryDefinitions.scheme
  parsepluginspec = opt: p: let
    optional = if builtins.isBool (p.optional or null) then p.optional else opt;

    attrsyn = p ? plugin && builtins.isAttrs (p.config or null);
    hmsyn = p ? plugin && p ? type && !builtins.isAttrs (p.config or {});
    nixossyn = p ? plugin && !(p ? type) && !builtins.isAttrs (p.config or {});

    type = if !(p ? config) then null
      else if nixossyn then "viml"
      else if hmsyn then p.type
      else if attrsyn then
        if p.config ? vim then "viml"
        else if p.config ? lua then "lua"
        else null
      else null;

    config =
      if attrsyn then
        if type == "viml"
        then if !(p.config ? lua)
          then
            p.config.vim
          else
            (p.config.vim + ''

              lua << NIXCATSVIMLUA
                ${p.config.lua}
              NIXCATSVIMLUA
            '')
        else p.config.lua or null
      else if hmsyn || nixossyn then p.config
      else null;

    plugin = if p ? plugin && p ? name
      then p.plugin // { pname = p.name; }
      else p.plugin or p;
  in
  if p ? plugin then {
    inherit config type optional plugin;
  } else {
    plugin = p;
    inherit optional;
  };

  # this is basically back to what was in nixpkgs except using my parsing function
  genPluginList = packageName: { start ? [ ], opt ? [ ], }:
    (map (parsepluginspec false) start) ++ (map (parsepluginspec true) opt);

  pluginsWithConfig = lib.flatten (lib.mapAttrsToList genPluginList pluginsOG);

in {
  plugins = map (v: { inherit (v) plugin optional; }) pluginsWithConfig;
  luaPluginConfigs = with builtins; lib.pipe pluginsWithConfig [
    (map (v: if v.type or "" == "lua" then v.config else null))
    (filter (v: v != null))
    lib.unique
    (concatStringsSep "\n")
  ];
  vimlPluginConfigs = with builtins; lib.pipe pluginsWithConfig [
    (map (v: if v.type or "" == "viml" then v.config else null))
    (filter (v: v != null))
    lib.unique
    (concatStringsSep "\n")
  ];
}
