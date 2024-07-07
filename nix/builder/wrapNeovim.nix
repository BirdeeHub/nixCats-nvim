rec {
# Source: https://github.com/NixOS/nixpkgs/blob/41de143fda10e33be0f47eab2bfe08a50f234267/pkgs/applications/editors/neovim/utils.nix#L24C9-L24C9
  # this is the code for wrapNeovim from nixpkgs
  wrapNeovim = pkgs: neovim-unwrapped: pkgs.lib.makeOverridable (legacyWrapper pkgs neovim-unwrapped);

  # and this is the code from neovimUtils that it calls
  legacyWrapper = pkgs: neovim: {
    extraMakeWrapperArgs ? ""
    /* the function you would have passed to python.withPackages */
    # , extraPythonPackages ? (_: [])
    /* the function you would have passed to python.withPackages */
    , withPython3 ? true,  extraPython3Packages ? (_: [])
    /* the function you would have passed to lua.withPackages */
    , extraLuaPackages ? (_: [])
    , withPerl ? false
    , withNodeJs ? false
    , withRuby ? true
    , vimAlias ? false
    , viAlias ? false
    , configure ? {}
    , extraName ? ""
    , nixCats
    , runB4Config
    , aliases
    , nixCats_passthru ? {}
    , extraPython3wrapperArgs ? []
  }:
    let
      plugins = pkgs.lib.flatten (pkgs.lib.mapAttrsToList genPluginList (configure.packages or {}));

      # can parse programs.neovim plugin syntax for both nixos and home module, in addition to just a derivation.
      # or even another one with config.lua or config.vim
      # especially ugly because I went for "both backwards and cross compatibility" XD
      parsepluginspec = opt: p: let
        optional = if p ? optional && builtins.isBool p.optional then p.optional else opt;

        attrsyn = p ? plugin && p ? config && builtins.isAttrs p.config;
        hmsyn = p ? plugin && p ? config && ! builtins.isAttrs p.config && p ? type;
        nixossyn = p ? plugin && p ? config && ! builtins.isAttrs p.config && ! p ? type;

        type = if ! p ? config then null else if nixossyn then "viml" else if hmsyn then p.type
          else if attrsyn then
            if p.config ? lua then "lua"
            else if p.config ? vim then "viml"
            else null
          else null;
      in
        (if nixossyn || hmsyn || attrsyn
        then (p // { config = let 
            lua = if type == "lua" then ''
              lua << EOF
              ${if attrsyn then p.config.lua else p.config}
              EOF
            '' else "";
            vim = if type == "viml" then
              if attrsyn then p.config.vim else p.config
            else "";
          in
          (vim + "\n" + lua); inherit optional; })
        else if p ? plugin then p // { inherit optional; }
        else { plugin = p; inherit optional; });

      # this is basically back to what was in nixpkgs except using my parsing function
      # and also adding the setup script before anything by loading it first with a fake plugin.
      genPluginList = packageName: {start ? [], opt ? []}:
        [ {
          plugin = pkgs.stdenv.mkDerivation {
            name = "empty-derivation";
            builder = builtins.toFile "builder.sh" ''
              source $stdenv/setup
              mkdir -p $out
            '';
          };
          config = runB4Config;
          optional = false;
        } ] ++ (map (parsepluginspec false) start) ++ (map (parsepluginspec true) opt);

      res = pkgs.neovimUtils.makeNeovimConfig {
        customRC = configure.customRC or "";
        inherit withPython3 extraPython3Packages;
        inherit withNodeJs withRuby viAlias vimAlias;
        inherit extraLuaPackages;
        inherit plugins;
        inherit extraName;
      };
    in
    (pkgs.callPackage ./wrapper.nix {}) neovim (res // {
      wrapperArgs = pkgs.lib.escapeShellArgs res.wrapperArgs + " " + extraMakeWrapperArgs;
      # I handle this with customRC 
      # otherwise it will get loaded in at the wrong time after startup plugins.
      wrapRc = true;
      customAliases = aliases;
      inherit (nixCats_passthru) nixCats_packageName;
      inherit withPerl extraPython3wrapperArgs nixCats nixCats_passthru;
  });
}
