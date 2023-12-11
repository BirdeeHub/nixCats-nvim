rec {
# Source: https://github.com/NixOS/nixpkgs/blob/41de143fda10e33be0f47eab2bfe08a50f234267/pkgs/applications/editors/neovim/utils.nix#L24C9-L24C9
  # this is the code for wrapNeovim from nixpkgs
  wrapNeovim = pkgs: neovim-unwrapped: pkgs.lib.makeOverridable (legacyWrapper pkgs neovim-unwrapped);

  # and this is the code from neovimUtils that it calls
  legacyWrapper = pkgs: neovim: {
    extraMakeWrapperArgs ? ""
    /* the function you would have passed to python.withPackages */
    , extraPythonPackages ? (_: [])
    /* the function you would have passed to python.withPackages */
    , withPython3 ? true,  extraPython3Packages ? (_: [])
    /* the function you would have passed to lua.withPackages */
    , extraLuaPackages ? (_: [])
    , withNodeJs ? false
    , withRuby ? true
    , vimAlias ? false
    , viAlias ? false
    , configure ? {}
    , extraName ? ""
  }:
    let
      # although I removed an error that doesnt make sense for my flake.
      plugins = pkgs.lib.flatten (pkgs.lib.mapAttrsToList genPlugin (configure.packages or {}));
      genPlugin = packageName: {start ? [], opt ? []}:
        start ++ (map (p: { plugin = p; optional = true; }) opt);

      res = pkgs.neovimUtils.makeNeovimConfig {
        customRC = configure.customRC or "";
        inherit withPython3 extraPython3Packages;
        inherit withNodeJs withRuby viAlias vimAlias;
        inherit extraLuaPackages;
        inherit plugins;
        inherit extraName;
      };
    in
    # it uses the new wrapper!!!
    pkgs.wrapNeovimUnstable neovim (res // {
      wrapperArgs = pkgs.lib.escapeShellArgs res.wrapperArgs + " " + extraMakeWrapperArgs;
      # I handle this with customRC 
      # otherwise it will get loaded in at the wrong time after startup plugins.
      wrapRc = true;
  });
}
