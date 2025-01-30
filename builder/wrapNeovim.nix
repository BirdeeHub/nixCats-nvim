# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
# derived from:
# https://github.com/NixOS/nixpkgs/blob/8564cb1517f118e1e90b8bc9ba052678f1aa4603/pkgs/applications/editors/neovim/utils.nix#L26-L122
{
  withPerl ? false,
  vimAlias ? false,
  viAlias ? false,
  extraName ? "",
  customRC ? "",
  extraPython3wrapperArgs ? [ ],
  preWrapperShellCode ? "",
  withPython3 ? true,
  # the function you would have passed to python3.withPackages
  extraPython3Packages ? (_: [ ]),
  withNodeJs ? false,
  withRuby ? true,
  gem_path ? null,
  collate_grammars ? true,
  # the function you would have passed to lua.withPackages
  extraLuaPackages ? (_: [ ]),
  nixCats_passthru ? { },
  neovim-unwrapped,

  aliases ? null,
  extraMakeWrapperArgs ? "",
  # expects a list of sets with plugin and optional
  # expects { plugin=far-vim; optional = false; }
  plugins ? [ ],
  # function to pass to vim-pack-dir that creates nixCats plugin
  nixCats,
  ncTools,
  pkgs,
  ...
}@args:
let
  inherit (pkgs) lib;
  # gets plugin.dependencies from
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vim/plugins/overrides.nix
  findDependenciesRecursively = plugins: lib.concatMap transitiveClosure plugins;
  transitiveClosure = plugin:
    [ plugin ] ++ (builtins.concatLists (map transitiveClosure plugin.dependencies or []));

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
  pluginsPartitioned = lib.partition (x: x.optional == true) plugins;
  opt = map (x: x.plugin) pluginsPartitioned.right;
  depsOfOptionalPlugins = lib.subtractLists opt (findDependenciesRecursively opt);
  startWithDeps = lib.pipe pluginsPartitioned.wrong [
    (map (x: x.plugin))
    findDependenciesRecursively
  ];
  start = startWithDeps ++ depsOfOptionalPlugins;

  allPython3Dependencies = ps: lib.pipe (start ++ opt) [
    (map (plugin: (plugin.python3Dependencies or (_: [])) ps))
    lib.flatten
    (res: (if withPython3 then [ ps.pynvim ] ++ (extraPython3Packages ps) else []) ++ res)
    lib.unique
  ];
  python3Env = pkgs.python3Packages.python.withPackages allPython3Dependencies;
  luaEnv = neovim-unwrapped.lua.withPackages extraLuaPackages;

  ## Here we calculate all of the arguments to the 1st call of `makeWrapper`
  # We start with the executable itself NOTE we call this variable "initial"
  # because if configure != {} we need to call makeWrapper twice, in order to
  # avoid double wrapping, see comment near finalMakeWrapperArgs
  makeWrapperArgs =
    let
      binPath = lib.makeBinPath (
        lib.optionals withRuby [ rubyEnv ] ++ lib.optionals withNodeJs [ pkgs.nodejs ]
      );
    in
    [
      "--inherit-argv0"
    ] ++ lib.optionals withRuby [
      "--set" "GEM_HOME" "${rubyEnv}/${rubyEnv.ruby.gemPath}"
    ] ++ lib.optionals (binPath != "") [
      "--suffix" "PATH" ":" binPath
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

in
(pkgs.callPackage ./wrapper.nix { }) (args // {
  wrapperArgsStr = pkgs.lib.escapeShellArgs makeWrapperArgs + " " + extraMakeWrapperArgs;
  inherit vimPackDir;
  inherit python3Env;
  inherit luaEnv;
  inherit withNodeJs;
  customAliases = aliases;
  inherit (nixCats_passthru) nixCats_packageName;
} // lib.optionalAttrs withRuby {
  inherit rubyEnv;
})
