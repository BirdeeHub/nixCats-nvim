# derived from:
# https://github.com/NixOS/nixpkgs/blob/8564cb1517f118e1e90b8bc9ba052678f1aa4603/pkgs/applications/editors/neovim/utils.nix#L126-L164
{
  pkgs,
  neovim-unwrapped,
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
  extraName ? "",
  customRC ? "",
  # this used to be called configure, and have customRC in it
  pluginsOG ? { },
  # I passed some more stuff in also
  nixCats,
  aliases,
  nixCats_passthru ? { },
  extraPython3wrapperArgs ? [ ],
  preWrapperShellCode ? "",
  gem_path ? null,
  collate_grammars ? false,
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

  pluginsWithConfig = pkgs.lib.flatten (pkgs.lib.mapAttrsToList genPluginList pluginsOG);

  # we process plugin spec style configurations here ourselves rather than using makeNeovimConfig for that.
  plugins = map (v: { inherit (v) plugin optional; }) pluginsWithConfig;
  lcfgs = builtins.filter (v: v != null) (map (v: if v.type or "" == "lua" then v.config else null) pluginsWithConfig);
  vcfgs = builtins.filter (v: v != null) (map (v: if v.type or "" == "viml" then v.config else null) pluginsWithConfig);
  luaPluginConfigs = builtins.concatStringsSep "\n" lcfgs;
  vimlPluginConfigs = builtins.concatStringsSep "\n" vcfgs;

  # was once neovimUtils.makeNeovimConfig
  res = import ./wrapenvs.nix {
    inherit withPython3 extraPython3Packages;
    inherit withNodeJs withRuby viAlias vimAlias;
    inherit extraLuaPackages;
    inherit plugins;
    inherit extraName;
    # but now it gets the luaEnv from the actual neovim-unwrapped you used
    # instead of the one in the neovim-unwrapped from the nixpkgs you used
    inherit neovim-unwrapped;
    inherit pkgs;
    inherit gem_path;
  };
in
(pkgs.callPackage ./wrapper.nix { }) neovim-unwrapped ( res // {
    wrapperArgs = pkgs.lib.escapeShellArgs res.wrapperArgs + " " + extraMakeWrapperArgs;
    customAliases = aliases;
    inherit (nixCats_passthru) nixCats_packageName;
    inherit withPerl extraPython3wrapperArgs nixCats nixCats_passthru
      customRC luaPluginConfigs vimlPluginConfigs preWrapperShellCode collate_grammars;
  }
)
