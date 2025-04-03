# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
# derived from:
# https://github.com/NixOS/nixpkgs/blob/8564cb1517f118e1e90b8bc9ba052678f1aa4603/pkgs/applications/editors/neovim/utils.nix#L26-L122
{
  extraName ? "",
  customAliases ? [],
  bashBeforeWrapper ? [],
  collate_grammars ? true,
  # the function you would have passed to lua.withPackages
  extraLuaPackages ? (_: [ ]),
  nixCats_packageName,
  neovim-unwrapped,
  autowrapRuntimeDeps ? "suffix",
  nvim_host_args ? [],
  nvim_host_vars ? [],
  host_phase ? "",
  makeWrapperArgs ? [],
  extraMakeWrapperArgs ? "",
  start ? [ ],
  opt ? [ ],
  # function to pass to vim-pack-dir that creates nixCats plugin
  nixCats,
  nclib,
  pkgs,
  ...
}:
let
  inherit (pkgs) lib;

  luaEnv = neovim-unwrapped.lua.withPackages extraLuaPackages;

  mkWrapperArgs =
    let
      autowrapped = lib.pipe (start ++ opt) [
        (builtins.foldl' (acc: v: acc ++ v.runtimeDeps or []) [])
        lib.unique
      ];
    in
    [
      "--inherit-argv0"
    ] ++ nvim_host_args ++ [
      "--prefix" "LUA_PATH" ";" (neovim-unwrapped.lua.pkgs.luaLib.genLuaPathAbsStr luaEnv)
      "--prefix" "LUA_CPATH" ";" (neovim-unwrapped.lua.pkgs.luaLib.genLuaCPathAbsStr luaEnv)
    ] ++ lib.optionals (autowrapRuntimeDeps == "prefix" && autowrapped != []) [
      "--prefix" "PATH" ":" (lib.makeBinPath autowrapped)
    ] ++ makeWrapperArgs ++
    lib.optionals ((autowrapRuntimeDeps == "suffix" || autowrapRuntimeDeps == true) && autowrapped != []) [
      "--suffix" "PATH" ":" (lib.makeBinPath autowrapped)
    ];

  vimPackDir = pkgs.callPackage ./vim-pack-dir.nix {
    inherit collate_grammars nixCats nclib;
    startup = lib.unique start;
    opt = lib.unique opt;
  };

  preWrapperShellCode = let
    xtra = /*bash*/''
      NVIM_WRAPPER_PATH_NIX="$(${pkgs.coreutils}/bin/readlink -f "$0")"
      export NVIM_WRAPPER_PATH_NIX
    '';
  in builtins.concatStringsSep "\n" ([xtra] ++ bashBeforeWrapper);

in
(pkgs.callPackage ./wrapper.nix { }) {
  wrapperArgsStr = lib.escapeShellArgs mkWrapperArgs + " " + extraMakeWrapperArgs;
  inherit vimPackDir luaEnv customAliases neovim-unwrapped
    nixCats_packageName host_phase nvim_host_vars preWrapperShellCode extraName;
}
