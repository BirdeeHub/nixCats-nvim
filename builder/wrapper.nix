# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
# Derived from:
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/neovim/wrapper.nix
{ stdenv
, lib
, gnused
}:
{
  neovim-unwrapped
  , nvim_host_vars ? []
  , host_phase ? ""
  , vimPackDir
  , wrapperArgsStr ? ""
  , nixCats_packageName
  , customAliases ? []
  , bashBeforeWrapper ? ""
  , luaEnv
  # lets you append stuff to the derivation name so that you can search for it in the store easier
  , extraName ? ""
  , ...
}: let
  generateCmdArg = extra: let
    concat_lua_args = lib.flip lib.pipe [
      (builtins.concatStringsSep ";")
      (res: ''--cmd "lua '' + res + ''"'')
    ];
  in [
    # vim accepts a limited number of commands so we join them all
    "--add-flags" (concat_lua_args (nvim_host_vars ++ [
      "vim.opt.packpath:prepend([[${vimPackDir}]])"
      "vim.opt.runtimepath:prepend([[${vimPackDir}]])"
      "vim.g[ [[nixCats-special-rtp-entry-vimPackDir]] ] = [[${vimPackDir}]]"
      "vim.g[ [[nixCats-special-rtp-entry-nvimLuaEnv]] ] = [[${luaEnv}]]"
      "local configdir = vim.fn.stdpath([[config]])"
      "vim.opt.packpath:remove(configdir)"
      "vim.opt.runtimepath:remove(configdir)"
      "vim.opt.runtimepath:remove(configdir .. [[/after]])"
    ] ++ extra))
  ];

  # If configure != {}, we can't generate the rplugin.vim file with e.g
  # NVIM_SYSTEM_RPLUGIN_MANIFEST *and* NVIM_RPLUGIN_MANIFEST env vars set in
  # the wrapper. That's why only when configure != {} (tested both here and
  # when postBuild is evaluated), we call makeWrapper once to generate a
  # wrapper with most arguments we need, excluding those that cause problems to
  # generate rplugin.vim, but still required for the final wrapper.
  finalMakeWrapperArgs =
    [ "${neovim-unwrapped}/bin/nvim" "${placeholder "out"}/bin/temp-nvim-wrapper" ]
    ++ [ "--set" "NVIM_SYSTEM_RPLUGIN_MANIFEST" "${placeholder "out"}/rplugin.vim" ]
    ++ generateCmdArg [
      "configdir = require([[nixCats]]).configDir"
      "vim.opt.packpath:prepend(configdir)"
      "vim.opt.runtimepath:prepend(configdir)"
      "vim.opt.runtimepath:append(configdir .. [[/after]])"
    ];

in {
  name = "neovim-${lib.getVersion neovim-unwrapped}-${nixCats_packageName}${lib.optionalString (extraName != "") "-${extraName}"}";
  meta = neovim-unwrapped.meta // {
    mainProgram = nixCats_packageName;
    maintainers = neovim-unwrapped.meta.maintainers ++ (if lib.maintainers ? birdee then [ lib.maintainers.birdee ] else []);
  };
  inherit bashBeforeWrapper;
  buildPhase = /*bash*/ ''
    runHook preBuild
    mkdir -p $out/bin
    [ -d ${neovim-unwrapped}/nix-support ] && \
    mkdir -p $out/nix-support && \
    cp -r ${neovim-unwrapped}/nix-support/* $out/nix-support
  ''
  + lib.optionalString stdenv.isLinux ''
    mkdir -p $out/share/applications
    substitute ${neovim-unwrapped}/share/applications/nvim.desktop $out/share/applications/${nixCats_packageName}.desktop \
      --replace-fail 'Name=Neovim' 'Name=${nixCats_packageName}'\
      --replace-fail 'TryExec=nvim' 'TryExec=${nixCats_packageName}'\
      --replace-fail 'Icon=nvim' 'Icon=${neovim-unwrapped}/share/icons/hicolor/128x128/apps/nvim.png'
    ${gnused}/bin/sed -i '/^Exec=nvim/c\Exec=${nixCats_packageName} "%F"' $out/share/applications/${nixCats_packageName}.desktop
    ''
  + builtins.concatStringsSep "\n" (builtins.map (alias: ''
    ln -s $out/bin/${nixCats_packageName} $out/bin/${alias}
  '') customAliases)
  + "\n" + host_phase + "\n"
  + (let
    manifestWrapperArgs =
      [ "${neovim-unwrapped}/bin/nvim" "${placeholder "out"}/bin/nvim-wrapper" ] ++ generateCmdArg [];
  in /* bash */ ''
    echo "Generating remote plugin manifest"
    export NVIM_RPLUGIN_MANIFEST=$out/rplugin.vim
    makeWrapper ${lib.escapeShellArgs manifestWrapperArgs} ${wrapperArgsStr}
    # some plugins expect $HOME to exist or they throw at startup
    export HOME="$(mktemp -d)"
    # Launch neovim without customRC, as UpdateRemotePlugins will scan our plugins regardless
    # and we dont want to run our init.lua
    # which would slow down the build and turn config errors into build errors.
    # Also pass various flags to disable temp file generation
    # (swap/viminfo) and redirect errors to stderr.
    # Only display the log on error since it will contain a few normally
    # irrelevant messages.
    if ! $out/bin/nvim-wrapper -i NONE -n -V1rplugins.log \
      +UpdateRemotePlugins +quit! > outfile 2>&1; then
      cat outfile
      echo -e "\nGenerating rplugin.vim failed!"
      exit 1
    fi
    rm "${placeholder "out"}/bin/nvim-wrapper"
    touch $out/rplugin.vim
  '')
  + /* bash */ ''
    # see:
    # https://github.com/NixOS/nixpkgs/issues/318925
    echo "Looking for lua dependencies..."
    source ${neovim-unwrapped.lua}/nix-support/utils.sh || true
    _addToLuaPath "${vimPackDir}" || true
    echo "propagated dependency path for plugins: $LUA_PATH"
    echo "propagated dependency cpath for plugins: $LUA_CPATH"
    makeWrapper ${lib.escapeShellArgs finalMakeWrapperArgs} ${wrapperArgsStr} \
        --prefix LUA_PATH ';' "$LUA_PATH" \
        --prefix LUA_CPATH ';' "$LUA_CPATH" \
        --set-default VIMINIT 'lua nixCats.init_main()'

    # add wrapper path to an environment variable
    # so that configuration may easily reference the path of the wrapper
    # for things like vim-startuptime
    # Grab the shebang
    head -1 ${placeholder "out"}/bin/temp-nvim-wrapper > ${placeholder "out"}/bin/${nixCats_packageName}
    # add the code to set the environment variable
    if [ -e "$bashBeforeWrapperPath" ]; then
      cat "$bashBeforeWrapperPath" >> ${placeholder "out"}/bin/${nixCats_packageName}
    else
      echo "$bashBeforeWrapper" >> ${placeholder "out"}/bin/${nixCats_packageName}
    fi
    echo >> ${placeholder "out"}/bin/${nixCats_packageName}
    # add the rest of the file back
    tail -n +2 ${placeholder "out"}/bin/temp-nvim-wrapper >> ${placeholder "out"}/bin/${nixCats_packageName}
    rm ${placeholder "out"}/bin/temp-nvim-wrapper
    chmod +x ${placeholder "out"}/bin/${nixCats_packageName}
    runHook postBuild
  '';
}
