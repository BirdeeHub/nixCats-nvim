# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
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
  collate_grammars ? true,
}:
let
  normalized = pkgs.callPackage ./normalizePlugins.nix { inherit pluginsOG; };
  # was once neovimUtils.makeNeovimConfig
  res = import ./wrapenvs.nix {
    inherit withPython3 extraPython3Packages;
    inherit withNodeJs withRuby viAlias vimAlias;
    inherit extraLuaPackages;
    inherit extraName;
    # but now it gets the luaEnv from the actual neovim-unwrapped you used
    # instead of the one in the neovim-unwrapped from the nixpkgs you used
    inherit neovim-unwrapped;
    inherit pkgs;
    inherit gem_path;
    inherit collate_grammars;
    inherit nixCats;
    inherit (normalized) plugins;
  };
in
(pkgs.callPackage ./wrapper.nix { }) (res // {
    wrapperArgsStr = pkgs.lib.escapeShellArgs res.wrapperArgs + " " + extraMakeWrapperArgs;
    customAliases = aliases;
    inherit (nixCats_passthru) nixCats_packageName;
    inherit (normalized) luaPluginConfigs vimlPluginConfigs;
    inherit withPerl extraPython3wrapperArgs nixCats_passthru
      customRC preWrapperShellCode collate_grammars;
  }
)
