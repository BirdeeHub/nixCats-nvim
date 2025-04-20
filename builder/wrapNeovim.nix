# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
# derived from:
# https://github.com/NixOS/nixpkgs/blob/8564cb1517f118e1e90b8bc9ba052678f1aa4603/pkgs/applications/editors/neovim/utils.nix#L26-L122
{
  preORpostPATH ? "--suffix",
  userPathEnv ? [],
  preORpostLD ? "--suffix",
  userLinkables ? [],
  userEnvVars ? [],
  configDirName ? null,
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
  extraMakeWrapperArgs ? [],
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

  normSpecs = control: var: maker: lib.flip lib.pipe [
    (lib.partition (p: p.value or null != null && ((p.pre or false == true && control == "--suffix") || (p.pre or true == false && control == "--prefix"))))
    ({ right ? [], wrong ? []}: {
      pre = map (p: p.value or p) (if control == "--suffix" then right else wrong);
      post = map (p: p.value or p) (if control == "--prefix" then right else wrong);
    })
    ({ pre ? [], post ? [] }: lib.optionals (pre != []) [ "--prefix" var ":" (maker pre) ] ++ lib.optionals (post != []) [ "--suffix" var ":" (maker post) ])
  ];

  luaEnv = neovim-unwrapped.lua.withPackages extraLuaPackages;

  # cat our args
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
  mkWrapperArgs = let
    autowrapped = lib.pipe (start ++ opt) [
      (builtins.foldl' (acc: v: acc ++ v.runtimeDeps or []) [])
      lib.unique
    ];
  in [
    "--inherit-argv0"
  ] ++ nvim_host_args ++ [
    "--prefix" "LUA_PATH" ";" (neovim-unwrapped.lua.pkgs.luaLib.genLuaPathAbsStr luaEnv)
    "--prefix" "LUA_CPATH" ";" (neovim-unwrapped.lua.pkgs.luaLib.genLuaCPathAbsStr luaEnv)
  ] ++ lib.optionals (autowrapRuntimeDeps == "prefix" && autowrapped != []) [
    "--prefix" "PATH" ":" (lib.makeBinPath autowrapped)
  ] ++ pkgs.lib.optionals (configDirName != null && configDirName != "" || configDirName != "nvim") [
    "--set" "NVIM_APPNAME" configDirName
  ] ++ normSpecs preORpostPATH "PATH" pkgs.lib.makeBinPath userPathEnv
  ++ normSpecs preORpostLD "LD_LIBRARY_PATH" pkgs.lib.makeLibraryPath userLinkables
  ++ lib.optionals ((autowrapRuntimeDeps == "suffix" || autowrapRuntimeDeps == true) && autowrapped != []) [
    "--suffix" "PATH" ":" (lib.makeBinPath autowrapped)
  ] ++ userEnvVars ++ makeWrapperArgs;

  vimPack = pkgs.callPackage ./vim-pack-dir.nix {
    inherit collate_grammars nixCats nclib;
    startup = lib.unique start;
    opt = lib.unique opt;
  };

in
(pkgs.callPackage ./wrapper.nix { }) {
  wrapperArgsStr = builtins.concatStringsSep " " ([ (lib.escapeShellArgs mkWrapperArgs) ] ++ extraMakeWrapperArgs);
  bashBeforeWrapper = builtins.concatStringsSep "\n" bashBeforeWrapper;
  inherit (vimPack) nixCatsPath vimPackDir;
  inherit luaEnv customAliases neovim-unwrapped
    nixCats_packageName host_phase nvim_host_vars extraName;
}
