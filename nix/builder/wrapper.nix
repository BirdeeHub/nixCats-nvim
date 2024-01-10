{ stdenv, symlinkJoin, lib, makeWrapper
, writeText
, nodePackages
, python3
, python3Packages
, callPackage
, neovimUtils
, vimUtils
, perl
, lndir
}:
neovim-unwrapped:

let
  wrapper = {
      extraName ? ""
    # should contain all args but the binary. Can be either a string or list
    , wrapperArgs ? []
    # a limited RC script used only to generate the manifest for remote plugins
    , manifestRc ? null
    , withPython2 ? false
    , withPython3 ? true,  python3Env ? python3
    , withNodeJs ? false
    , withPerl ? false
    , rubyEnv ? null
    , vimAlias ? false
    , viAlias ? false

    # additional argument not generated by makeNeovimConfig
    # it will append "-u <customRc>" to the wrapped arguments
    # set to false if you want to control where to save the generated config
    # (e.g., in ~/.config/init.vim or project/.nvimrc)
    , wrapRc ? true
    # vimL code that should be sourced as part of the generated init.lua file
    , neovimRcContent ? null
    # lua code to put into the generated init.lua file
    , luaRcContent ? ""
    # entry to load in packpath
    , packpathDirs
    , nixCats
    , customAliases ? null
    , ...
  }:
  assert withPython2 -> throw "Python2 support has been removed from the neovim wrapper, please remove withPython2 and python2Env.";

  stdenv.mkDerivation (finalAttrs:
  let

    rcContent = ''
      ${luaRcContent}
    '' + lib.optionalString (!isNull neovimRcContent) ''
      vim.cmd.source "${writeText "init.vim" neovimRcContent}"
    '';

    wrapperArgsStr = if lib.isString wrapperArgs then wrapperArgs else lib.escapeShellArgs wrapperArgs;

    generatedWrapperArgs =
      # vim accepts a limited number of commands so we join them all
          [
            "--add-flags" ''--cmd "lua ${providerLuaRc}"''
            # (lib.intersperse "|" hostProviderViml)
          ] ++ lib.optionals (packpathDirs.myNeovimPackages.start != [] || packpathDirs.myNeovimPackages.opt != [])
          (let packDir = (callPackage ./vim-pack-dir.nix {}).packDir nixCats packpathDirs;
            in [
            "--add-flags" ''--cmd "set packpath^=${packDir}"''
            "--add-flags" ''--cmd "set rtp^=${packDir}"''
            "--add-flags" ''--cmd "lua vim.g[ [[nixCats-special-rtp-entry-vimPackDir]] ] = [[${packDir}]]"''
          ])
          ;

    providerLuaRc = neovimUtils.generateProviderRc {
      inherit withPython3 withNodeJs withPerl;
      withRuby = rubyEnv != null;
    };

    # If configure != {}, we can't generate the rplugin.vim file with e.g
    # NVIM_SYSTEM_RPLUGIN_MANIFEST *and* NVIM_RPLUGIN_MANIFEST env vars set in
    # the wrapper. That's why only when configure != {} (tested both here and
    # when postBuild is evaluated), we call makeWrapper once to generate a
    # wrapper with most arguments we need, excluding those that cause problems to
    # generate rplugin.vim, but still required for the final wrapper.
    finalMakeWrapperArgs =
      [ "${neovim-unwrapped}/bin/nvim" "${placeholder "out"}/bin/nvim" ]
      ++ [ "--set" "NVIM_SYSTEM_RPLUGIN_MANIFEST" "${placeholder "out"}/rplugin.vim" ]
      ++ lib.optionals finalAttrs.wrapRc [ "--add-flags" "-u ${writeText "init.lua" rcContent}" ]
      ++ finalAttrs.generatedWrapperArgs
      ;

    perlEnv = perl.withPackages (p: [ p.NeovimExt p.Appcpanminus ]);
  in {
      name = "neovim-${lib.getVersion neovim-unwrapped}${extraName}";

      __structuredAttrs = true;
      dontUnpack = true;
      inherit viAlias vimAlias withNodeJs withPython3 withPerl;
      inherit wrapRc providerLuaRc packpathDirs;
      inherit python3Env rubyEnv;
      withRuby = rubyEnv != null;
      inherit wrapperArgs generatedWrapperArgs;
      luaRcContent = rcContent;
      # Remove the symlinks created by symlinkJoin which we need to perform
      # extra actions upon
      postBuild = lib.optionalString stdenv.isLinux ''
        rm $out/share/applications/nvim.desktop
        substitute ${neovim-unwrapped}/share/applications/nvim.desktop $out/share/applications/nvim.desktop \
          --replace 'Name=Neovim' 'Name=Neovim wrapper'
      ''
      + lib.optionalString finalAttrs.withPython3 ''
        makeWrapper ${python3Env.interpreter} $out/bin/nvim-python3 --unset PYTHONPATH
      ''
      + lib.optionalString (finalAttrs.rubyEnv != null) ''
        ln -s ${finalAttrs.rubyEnv}/bin/neovim-ruby-host $out/bin/nvim-ruby
      ''
      + lib.optionalString finalAttrs.withNodeJs ''
        ln -s ${nodePackages.neovim}/bin/neovim-node-host $out/bin/nvim-node
      ''
      + lib.optionalString finalAttrs.withPerl ''
        ln -s ${perlEnv}/bin/perl $out/bin/nvim-perl
      ''
      + lib.optionalString finalAttrs.vimAlias ''
        ln -s $out/bin/nvim $out/bin/vim
      ''
      + lib.optionalString finalAttrs.viAlias ''
        ln -s $out/bin/nvim $out/bin/vi
      ''
      + lib.optionalString (customAliases != null)
      (builtins.concatStringsSep "\n" (builtins.map (alias: ''
        ln -s $out/bin/nvim $out/bin/${alias}
      '') customAliases))
      + lib.optionalString (manifestRc != null) (let
        manifestWrapperArgs =
          [ "${neovim-unwrapped}/bin/nvim" "${placeholder "out"}/bin/nvim-wrapper" ] ++ finalAttrs.generatedWrapperArgs;
      in /* bash */ ''
        echo "Generating remote plugin manifest"
        export NVIM_RPLUGIN_MANIFEST=$out/rplugin.vim
        makeWrapper ${lib.escapeShellArgs manifestWrapperArgs} ${wrapperArgsStr}

        # Some plugins assume that the home directory is accessible for
        # initializing caches, temporary files, etc. Even if the plugin isn't
        # actively used, it may throw an error as soon as Neovim is launched
        # (e.g., inside an autoload script), causing manifest generation to
        # fail. Therefore, let's create a fake home directory before generating
        # the manifest, just to satisfy the needs of these plugins.
        #
        # See https://github.com/Yggdroot/LeaderF/blob/v1.21/autoload/lfMru.vim#L10
        # for an example of this behavior.
        export HOME="$(mktemp -d)"
        # Launch neovim with a vimrc file containing only the generated plugin
        # code. Pass various flags to disable temp file generation
        # (swap/viminfo) and redirect errors to stderr.
        # Only display the log on error since it will contain a few normally
        # irrelevant messages.
        if ! $out/bin/nvim-wrapper \
          -u ${writeText "manifest.vim" manifestRc} \
          -i NONE -n \
          -V1rplugins.log \
          +UpdateRemotePlugins +quit! > outfile 2>&1; then
          cat outfile
          echo -e "\nGenerating rplugin.vim failed!"
          exit 1
        fi
        rm "${placeholder "out"}/bin/nvim-wrapper"
      '')
      + /* bash */ ''
        rm $out/bin/nvim
        touch $out/rplugin.vim
        makeWrapper ${lib.escapeShellArgs finalMakeWrapperArgs} ${wrapperArgsStr}
      '';

    buildPhase = ''
      runHook preBuild
      mkdir -p $out
      for i in ${neovim-unwrapped}; do
        lndir -silent $i $out
      done
      runHook postBuild
    '';

    preferLocalBuild = true;

    nativeBuildInputs = [ makeWrapper lndir ];
    passthru = {
      inherit providerLuaRc packpathDirs;
      unwrapped = neovim-unwrapped;
      initRc = neovimRcContent;
    };

    meta = neovim-unwrapped.meta // {
      # To prevent builds on hydra
      hydraPlatforms = [];
      # prefer wrapper over the package
      priority = (neovim-unwrapped.meta.priority or 0) - 1;
    };
  });
in
  lib.makeOverridable wrapper
