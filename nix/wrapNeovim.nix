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
    # except I also passed this through
    , wrapRc ? true
  }:
    let
      # and removed an error that doesnt make sense for my flake.
      plugins = pkgs.lib.flatten (pkgs.lib.mapAttrsToList genPlugin (configure.packages or {}));
      genPlugin = packageName: {start ? [], opt ? []}:
        start ++ (map (p: { plugin = p; optional = true; }) opt);

      res = pkgs.neovimUtils.makeNeovimConfig {
        inherit withPython3;
        inherit extraPython3Packages;
        inherit extraLuaPackages;
        inherit withNodeJs withRuby viAlias vimAlias;
        customRC = configure.customRC or "";
        inherit plugins;
        inherit extraName;
      };
    in
    pkgs.wrapNeovimUnstable neovim (res // {
      wrapperArgs = pkgs.lib.escapeShellArgs res.wrapperArgs + " " + extraMakeWrapperArgs;
      # and changed this
      inherit wrapRc;
  });
}
