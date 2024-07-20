# derived from:
# https://github.com/NixOS/nixpkgs/blob/8564cb1517f118e1e90b8bc9ba052678f1aa4603/pkgs/applications/editors/neovim/utils.nix#L126-L164
pkgs: neovim:
{
  extraMakeWrapperArgs ? "",
  # the function you would have passed to python.withPackages
  # , extraPythonPackages ? (_: [])
  # the function you would have passed to python.withPackages
  withPython3 ? true,
  extraPython3Packages ? (_: [ ]),
  # the function you would have passed to lua.withPackages
  extraLuaPackages ? (_: [ ]),
  withPerl ? false,
  withNodeJs ? false,
  withRuby ? true,
  vimAlias ? false,
  viAlias ? false,
  configure ? { },
  extraName ? "",
  # I passed some more stuff in
  nixCats,
  runB4Config,
  aliases,
  nixCats_passthru ? { },
  extraPython3wrapperArgs ? [ ],
}:
let
  # accepts 4 different plugin syntaxes, specified in :h nixCats.flake.outputs.categoryDefinitions.scheme
  parsepluginspec = opt: p: let
    optional = if p ? optional && builtins.isBool p.optional then p.optional else opt;

    attrsyn = p ? plugin && p ? config && builtins.isAttrs p.config;
    hmsyn = p ? plugin && p ? config && !builtins.isAttrs p.config && p ? type;
    nixossyn = p ? plugin && p ? config && !builtins.isAttrs p.config && !(p ? type);

    type = if !p ? config then null
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
        else p.config.lua
      else if hmsyn || nixossyn then p.config
      else null;
  in
  if p ? plugin then {
      inherit (p) plugin;
      inherit config type optional;
  } else {
    plugin = p;
    inherit optional;
  };

  # this is basically back to what was in nixpkgs except using my parsing function
  genPluginList = packageName: { start ? [ ], opt ? [ ], }:
    (map (parsepluginspec false) start) ++ (map (parsepluginspec true) opt);

  pluginsWithConfig = pkgs.lib.flatten (pkgs.lib.mapAttrsToList genPluginList (configure.packages or { }));

  # we process plugin spec style configurations here ourselves rather than using makeNeovimConfig for that.
  plugins = map (v: { inherit (v) plugin optional; }) pluginsWithConfig;
  lcfgs = builtins.filter (v: v != null) (map (v: if v ? type && v.type == "lua" then v.config else null) pluginsWithConfig);
  vcfgs = builtins.filter (v: v != null) (map (v: if v ? type && v.type == "viml" then v.config else null) pluginsWithConfig);
  luaPluginConfigs = builtins.concatStringsSep "\n" lcfgs;
  vimlPluginConfigs = builtins.concatStringsSep "\n" vcfgs;

  # this is basically back to what was in nixpkgs
  # except we didnt pass in customRC or any config included in plugin specs from nix.
  # this means the neovimRcContent variable it generates will always be empty
  # source for this function at:
  # https://github.com/NixOS/nixpkgs/blob/8564cb1517f118e1e90b8bc9ba052678f1aa4603/pkgs/applications/editors/neovim/utils.nix#L26-L122
  res = pkgs.neovimUtils.makeNeovimConfig {
    inherit withPython3 extraPython3Packages;
    inherit withNodeJs withRuby viAlias vimAlias;
    inherit extraLuaPackages;
    inherit plugins;
    inherit extraName;
  };
in
(pkgs.callPackage ./wrapper.nix { }) neovim ( res // {
    wrapperArgs = pkgs.lib.escapeShellArgs res.wrapperArgs + " " + extraMakeWrapperArgs;
    # I handle this with customRC 
    # otherwise it will get loaded in at the wrong time after startup plugins.
    wrapRc = true;
    # Then I pass a bunch of stuff through
    customAliases = aliases;
    runConfigInit = configure.customRC;
    inherit (nixCats_passthru) nixCats_packageName;
    inherit withPerl extraPython3wrapperArgs nixCats nixCats_passthru
      runB4Config luaPluginConfigs vimlPluginConfigs;
  }
)
