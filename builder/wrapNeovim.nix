# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
# derived from:
# https://github.com/NixOS/nixpkgs/blob/8564cb1517f118e1e90b8bc9ba052678f1aa4603/pkgs/applications/editors/neovim/utils.nix#L26-L122
{
  extraName ? "",
  vimAlias ? false,
  viAlias ? false,
  aliases ? null,
  customRC ? "",
  preWrapperShellCode ? "",
  extraPython3wrapperArgs ? [ ],
  withPython3 ? true,
  # the function you would have passed to python3.withPackages
  extraPython3Packages ? (_: [ ]),
  withNodeJs ? false,
  withPerl ? false,
  withRuby ? true,
  gem_path ? null,
  collate_grammars ? true,
  # the function you would have passed to lua.withPackages
  extraLuaPackages ? (_: [ ]),
  nixCats_packageName,
  neovim-unwrapped,
  autowrapRuntimeDeps ? "suffix",

  extraMakeWrapperArgs ? "",
  start ? [ ],
  opt ? [ ],
  # function to pass to vim-pack-dir that creates nixCats plugin
  nixCats,
  ncTools,
  pkgs,
  ...
}@args:
let
  inherit (pkgs) lib;
  gemPath = if gem_path != null then gem_path
    else "${pkgs.path}/pkgs/applications/editors/neovim/ruby_provider";
  rubyEnv = pkgs.bundlerEnv {
    name = "neovim-ruby-env";
    postBuild = ''
      ln -sf ${pkgs.ruby}/bin/* $out/bin
    '';
    gemdir = gemPath;
  };

  # get dependencies of plugins
  allPython3Dependencies = ps: lib.pipe (start ++ opt) [
    (map (plugin: (plugin.python3Dependencies or (_: [])) ps))
    lib.flatten
    (res: (if withPython3 then [ ps.pynvim ] ++ extraPython3Packages ps else []) ++ res)
    lib.unique
  ];
  python3Env = pkgs.python3Packages.python.withPackages allPython3Dependencies;
  luaEnv = neovim-unwrapped.lua.withPackages extraLuaPackages;
  perlEnv = pkgs.perl.withPackages (p: [ p.NeovimExt p.Appcpanminus ]);

  ## Here we calculate all of the arguments to the 1st call of `makeWrapper`
  # We start with the executable itself NOTE we call this variable "initial"
  # because if configure != {} we need to call makeWrapper twice, in order to
  # avoid double wrapping, see comment near finalMakeWrapperArgs
  makeWrapperArgs =
    let
      autowrapped = lib.pipe (start ++ opt) [
        (builtins.foldl' (acc: v: acc ++ v.runtimeDeps or []) [])
        lib.unique
      ];
      binPath = lib.makeBinPath (
        lib.optionals withRuby [
          rubyEnv
        ] ++ lib.optionals withNodeJs [
          pkgs.nodejs
        ] ++ lib.optionals (autowrapRuntimeDeps == "suffix" || autowrapRuntimeDeps == true) autowrapped
      );
    in
    [
      "--inherit-argv0"
    ] ++ lib.optionals withRuby [
      "--set" "GEM_HOME" "${rubyEnv}/${rubyEnv.ruby.gemPath}"
    ] ++ lib.optionals (binPath != "") [
      "--suffix" "PATH" ":" binPath
    ] ++ lib.optionals (autowrapRuntimeDeps == "prefix") [
      "--prefix" "PATH" ":" (lib.makeBinPath autowrapped)
    ] ++ lib.optionals (luaEnv != null) [
      "--prefix" "LUA_PATH" ";" (neovim-unwrapped.lua.pkgs.luaLib.genLuaPathAbsStr luaEnv)
      "--prefix" "LUA_CPATH" ";" (neovim-unwrapped.lua.pkgs.luaLib.genLuaCPathAbsStr luaEnv)
    ];

  vimPackDir = pkgs.callPackage ./vim-pack-dir.nix {
    inherit collate_grammars nixCats ncTools;
    python3Env = if allPython3Dependencies pkgs.python3.pkgs == [ ] then null else python3Env;
    startup = lib.unique start;
    opt = lib.unique opt;
  };

  customAliases = lib.unique (
    lib.optional viAlias "vi"
    ++ lib.optional vimAlias "vim"
    ++ lib.optionals (aliases != null) aliases
  );
in
(pkgs.callPackage ./wrapper.nix { }) (args // {
  wrapperArgsStr = lib.escapeShellArgs makeWrapperArgs + " " + extraMakeWrapperArgs;
  inherit vimPackDir python3Env luaEnv withNodeJs perlEnv customAliases;
  inherit nixCats_packageName;
} // lib.optionalAttrs withRuby {
  inherit rubyEnv;
})
