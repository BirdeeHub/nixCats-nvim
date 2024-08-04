# derived from:
# https://github.com/NixOS/nixpkgs/blob/8564cb1517f118e1e90b8bc9ba052678f1aa4603/pkgs/applications/editors/neovim/utils.nix#L26-L122
{ withPython3 ? true
/* the function you would have passed to python3.withPackages */
, extraPython3Packages ? (_: [ ])
, withNodeJs ? false
, withRuby ? true
, gem_path ? null
/* the function you would have passed to lua.withPackages */
, extraLuaPackages ? (_: [ ])

# expects a list of sets with plugin and optional
# expects { plugin=far-vim; optional = false; }
, plugins ? []

, neovim-unwrapped
, pkgs
, nixpkgs
, ...
}@args:
let
  inherit (pkgs) lib;
  gemPath = "${nixpkgs}/pkgs/applications/editors/neovim/ruby_provider";
  rubyEnv = pkgs.bundlerEnv ({
    name = "neovim-ruby-env";
    postBuild = ''
      ln -sf ${pkgs.ruby}/bin/* $out/bin
    '';
  } // (if builtins.pathExists gemPath then {
    gemdir = if gem_path != null then gem_path else gemPath;
  } else {}));

  requiredPluginsForPackage = { start ? [], opt ? []}:
    start ++ opt;
  pluginsPartitioned = lib.partition (x: x.optional == true) plugins;
  requiredPlugins = requiredPluginsForPackage myVimPackage;
  getDeps = attrname: map (plugin: plugin.${attrname} or (_: [ ]));
  myVimPackage = {
        start = map (x: x.plugin) pluginsPartitioned.wrong;
        opt = map (x: x.plugin) pluginsPartitioned.right;
  };

  pluginPython3Packages = getDeps "python3Dependencies" requiredPlugins;
  python3Env = pkgs.python3Packages.python.withPackages (ps:
    [ ps.pynvim ]
    ++ (extraPython3Packages ps)
    ++ (lib.concatMap (f: f ps) pluginPython3Packages));

  luaEnv = neovim-unwrapped.lua.withPackages extraLuaPackages;

  # as expected by packdir
  packpathDirs.myNeovimPackages = myVimPackage;
  ## Here we calculate all of the arguments to the 1st call of `makeWrapper`
  # We start with the executable itself NOTE we call this variable "initial"
  # because if configure != {} we need to call makeWrapper twice, in order to
  # avoid double wrapping, see comment near finalMakeWrapperArgs
  makeWrapperArgs =
    let
      binPath = lib.makeBinPath (lib.optionals withRuby [ rubyEnv ] ++ lib.optionals withNodeJs [ pkgs.nodejs ]);
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

in

builtins.removeAttrs args ["plugins"] // {
  wrapperArgs = makeWrapperArgs;
  inherit packpathDirs;
  inherit python3Env;
  inherit luaEnv;
  inherit withNodeJs;
} // lib.optionalAttrs withRuby {
  inherit rubyEnv;
}
