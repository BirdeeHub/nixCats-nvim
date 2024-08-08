# Derived from:
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/neovim/wrapper.nix
{ stdenv
, lib
, makeWrapper
, writeText
, nodePackages
, python3
, callPackage
, perl
, lndir
}:
neovim-unwrapped:
{
  # lets you append stuff to the derivation name so that you can search for it in the store easier
  extraName ? ""

  , withPython2 ? false
  , withPython3 ? true,  python3Env ? python3
  , withNodeJs ? false
  , withPerl ? false
  , rubyEnv ? null
  , vimAlias ? false
  , viAlias ? false

  # vim-pack-dir gets called on this
  # to resolve dependencies and other things
  # from plugins. It has all the plugins in it.
  , packpathDirs

  # should contain all args but the binary. Can be either a string or list
  , wrapperArgs ? []

  # I added stuff to the one from nixpkgs
  , nixCats
  , nixCats_packageName
  , customAliases ? null
  , nixCats_passthru ? {}
  , preWrapperShellCode ? ""
  , runB4Config ? ""
  , runConfigInit ? ""
  , luaEnv
  , extraPython3wrapperArgs ? []
  , luaPluginConfigs ? ""
  , vimlPluginConfigs ? ""
  , ...
}:
assert withPython2 -> throw "Python2 support has been removed from the neovim wrapper, please remove withPython2 and python2Env.";
let
  generateProviderRc = {
      withPython3 ? true
    , withNodeJs ? false
    , withRuby ? true
    # perl is problematic https://github.com/NixOS/nixpkgs/issues/132368
    , withPerl ? false
    , ...
    }: let
      hostprog_check_table = {
        node = withNodeJs;
        python = false;
        python3 = withPython3;
        ruby = withRuby;
        perl = withPerl;
      };

      # nixCats modified to start with packagename instead of nvim to avoid collisions with multiple neovims
      genProviderCommand = prog: withProg:
        if withProg then
          "vim.g.${prog}_host_prog='${placeholder "out"}/bin/${nixCats_packageName}-${prog}'"
        else
          "vim.g.loaded_${prog}_provider=0";

    hostProviderLua = lib.mapAttrsToList genProviderCommand hostprog_check_table;
  in
    lib.concatStringsSep ";" hostProviderLua;

  finalPackDir = (callPackage ./vim-pack-dir.nix {}) nixCats packpathDirs;

  # modified to allow more control over running things FIRST and also in which language.
  luaRcContent = ''
    vim.g[ [[nixCats-special-rtp-entry-vimPackDir]] ] = [[${finalPackDir}]]
    vim.g[ [[nixCats-special-rtp-entry-nvimLuaEnv]] ] = [[${luaEnv}]]
    ${runB4Config}
    ${runConfigInit}
    ${luaPluginConfigs}
  '' + (lib.optionalString (vimlPluginConfigs != "") ''
    vim.cmd.source([[${writeText "vim_configs_from_nix.vim" vimlPluginConfigs}]])
  '');

  providerLuaRc = generateProviderRc {
    inherit withPython3 withNodeJs withPerl;
    withRuby = rubyEnv != null;
  };

  preWrapperShellFile = writeText "preNixCatsWrapperShellCode" preWrapperShellCode;

  generatedWrapperArgs =
    # vim accepts a limited number of commands so we join them all
        [
          "--add-flags" ''--cmd "lua ${providerLuaRc}"''
          "--add-flags" ''--cmd "set packpath^=${finalPackDir}"''
          "--add-flags" ''--cmd "set rtp^=${finalPackDir}"''
        ];

  wrapperArgsStr = if lib.isString wrapperArgs then wrapperArgs else lib.escapeShellArgs wrapperArgs;

  # If configure != {}, we can't generate the rplugin.vim file with e.g
  # NVIM_SYSTEM_RPLUGIN_MANIFEST *and* NVIM_RPLUGIN_MANIFEST env vars set in
  # the wrapper. That's why only when configure != {} (tested both here and
  # when postBuild is evaluated), we call makeWrapper once to generate a
  # wrapper with most arguments we need, excluding those that cause problems to
  # generate rplugin.vim, but still required for the final wrapper.
  finalMakeWrapperArgs =
    [ "${neovim-unwrapped}/bin/nvim" "${placeholder "out"}/bin/${nixCats_packageName}" ]
    ++ [ "--set" "NVIM_SYSTEM_RPLUGIN_MANIFEST" "${placeholder "out"}/rplugin.vim" ]
    ++ [ "--add-flags" ''-u ${writeText "init.lua" luaRcContent}'' ]
    ++ generatedWrapperArgs
    ;

  perlEnv = perl.withPackages (p: [ p.NeovimExt p.Appcpanminus ]);

  manifestRc = "set nocompatible";
in
stdenv.mkDerivation {
  name = "neovim-${lib.getVersion neovim-unwrapped}${extraName}";

  __structuredAttrs = true;
  dontUnpack = true;
  inherit viAlias vimAlias customAliases;
  inherit python3Env rubyEnv perlEnv;
  # Remove the symlinks created by symlinkJoin which we need to perform
  # extra actions upon
  # nixCats: modified to start with packagename instead of nvim to avoid collisions with multiple neovims
  postBuild = lib.optionalString stdenv.isLinux ''
    rm $out/share/applications/nvim.desktop
    substitute ${neovim-unwrapped}/share/applications/nvim.desktop $out/share/applications/${nixCats_packageName}.desktop \
      --replace 'Name=Neovim' 'Name=${nixCats_packageName}'\
      --replace 'TryExec=nvim' 'TryExec=${nixCats_packageName}'\
      --replace 'Exec=nvim %F' 'Exec=${nixCats_packageName} %F'
  ''
  + lib.optionalString (python3Env != null && withPython3) ''
    makeWrapper ${python3Env.interpreter} $out/bin/${nixCats_packageName}-python3 --unset PYTHONPATH ${builtins.concatStringsSep " " extraPython3wrapperArgs}
  ''
  + lib.optionalString (rubyEnv != null) ''
    ln -s ${rubyEnv}/bin/neovim-ruby-host $out/bin/${nixCats_packageName}-ruby
  ''
  + lib.optionalString withNodeJs ''
    ln -s ${nodePackages.neovim}/bin/neovim-node-host $out/bin/${nixCats_packageName}-node
  ''
  + lib.optionalString (perlEnv != null && withPerl) ''
    ln -s ${perlEnv}/bin/perl $out/bin/${nixCats_packageName}-perl
  ''
  + lib.optionalString vimAlias ''
    ln -s $out/bin/${nixCats_packageName} $out/bin/vim
  ''
  + lib.optionalString viAlias ''
    ln -s $out/bin/${nixCats_packageName} $out/bin/vi
  ''
  # also I added this.
  + lib.optionalString (customAliases != null)
  (builtins.concatStringsSep "\n" (builtins.map (alias: ''
    ln -s $out/bin/${nixCats_packageName} $out/bin/${alias}
  '') customAliases))
  +
  (let
    manifestWrapperArgs =
      [ "${neovim-unwrapped}/bin/nvim" "${placeholder "out"}/bin/nvim-wrapper" ] ++ generatedWrapperArgs;
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
    # I only mostly understand the above 10 lines. They are from nixpkgs.
  '')

  + /* bash */ ''
    rm $out/bin/nvim
    touch $out/rplugin.vim
    # see:
    # https://github.com/NixOS/nixpkgs/issues/318925
    echo "Looking for lua dependencies..."
    # some older versions of nixpkgs do not have this file (23.11)
    # so ignore errors if it doesnt exist.
    # makeWrapper will still behave if the variables are not set
    source ${neovim-unwrapped.lua}/nix-support/utils.sh || true
    # added after release 24.05 so also ignore errors on this function
    _addToLuaPath "${finalPackDir}" || true
    echo "propagated dependency path for plugins: $LUA_PATH"
    echo "propagated dependency cpath for plugins: $LUA_CPATH"
    makeWrapper ${lib.escapeShellArgs finalMakeWrapperArgs} ${wrapperArgsStr} \
        --prefix LUA_PATH ';' "$LUA_PATH" \
        --prefix LUA_CPATH ';' "$LUA_CPATH"

    # add wrapper path to an environment variable
    # so that configuration may easily reference the path of the wrapper
    # for things like vim-startuptime
    export BASHCACHE=$(mktemp)
    # Grab the shebang
    head -1 ${placeholder "out"}/bin/${nixCats_packageName} > $BASHCACHE
    # add the code to set the environment variable
    cat ${preWrapperShellFile} >> $BASHCACHE
    # add the rest of the file back
    tail -n +2 ${placeholder "out"}/bin/${nixCats_packageName} >> $BASHCACHE
    cat $BASHCACHE > ${placeholder "out"}/bin/${nixCats_packageName}
    rm $BASHCACHE
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

  # modified to allow users to add passthru
  passthru = nixCats_passthru;

  # modified to have packagename instead of nvim
  meta = neovim-unwrapped.meta // {
    mainProgram = "${nixCats_packageName}";
    maintainers = neovim-unwrapped.meta.maintainers ++ (if lib.maintainers ? birdee then [ lib.maintainers.birdee ] else []);
  };
}
