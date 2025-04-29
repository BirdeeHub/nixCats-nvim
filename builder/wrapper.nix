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
  , nixCatsPath
  , wrapperArgsStr ? ""
  , nixCats_packageName
  , customAliases ? []
  , bashBeforeWrapper ? ""
  , luaEnv
  # lets you append stuff to the derivation name so that you can search for it in the store easier
  , extraName ? ""
  , ...
}: let
  luaSetupLines = nvim_host_vars ++ [
    "vim.opt.packpath:prepend('${vimPackDir}')"
    "vim.opt.runtimepath:prepend('${vimPackDir}')"
    "vim.g[ [[nixCats-special-rtp-entry-nixCats]] ] = '${nixCatsPath}'"
    "vim.g[ [[nixCats-special-rtp-entry-vimPackDir]] ] = '${vimPackDir}'"
    "vim.g[ [[nixCats-special-rtp-entry-nvimLuaEnv]] ] = '${luaEnv}'"
    "local configdir = vim.fn.stdpath([[config]])"
    "vim.opt.packpath:remove(configdir)"
    "vim.opt.runtimepath:remove(configdir)"
    "vim.opt.runtimepath:remove(configdir .. [[/after]])"
  ];
in {
  name = "neovim-${lib.getVersion neovim-unwrapped}-${nixCats_packageName}${lib.optionalString (extraName != "") "-${extraName}"}";
  meta = neovim-unwrapped.meta // {
    mainProgram = nixCats_packageName;
    maintainers = neovim-unwrapped.meta.teams ++ (if lib.maintainers ? birdee then [ lib.maintainers.birdee ] else []);
  };
  inherit bashBeforeWrapper;
  manifestLua = builtins.concatStringsSep "\n" luaSetupLines;
  setupLua = builtins.concatStringsSep "\n" ([
    "if nixCats then return end" # <- safety to prevent possible weirdness from --cmd being called twice by tmux-resurrect or similar
  ] ++ luaSetupLines ++ [
    "package.preload.nixCats = function() return dofile('${nixCatsPath}/lua/nixCats.lua') end"
    "configdir = require([[nixCats]]).configDir"
    "vim.opt.packpath:prepend(configdir)"
    "vim.opt.runtimepath:prepend(configdir)"
    "vim.opt.runtimepath:append(configdir .. [[/after]])"
  ]);
  buildPhase = /*bash*/ ''
    runHook preBuild
    mkdir -p $out/bin
    [ -d ${neovim-unwrapped}/nix-support ] && \
    mkdir -p $out/nix-support && \
    cp -r ${neovim-unwrapped}/nix-support/* $out/nix-support
  ''
  + lib.optionalString stdenv.isLinux ''
    mkdir -p $out/share/applications
    substitute ${lib.escapeShellArgs [ "${neovim-unwrapped}/share/applications/nvim.desktop" "${placeholder "out"}/share/applications/${nixCats_packageName}.desktop"
      "--replace-fail" "Name=Neovim" "Name=${nixCats_packageName}"
      "--replace-fail" "TryExec=nvim" "TryExec=${placeholder "out"}/bin/${nixCats_packageName}"
      "--replace-fail" "Icon=nvim" "Icon=${neovim-unwrapped}/share/icons/hicolor/128x128/apps/nvim.png" ]}
    ${gnused}/bin/sed -i ${lib.escapeShellArgs [ "/^Exec=nvim/c\\Exec=${placeholder "out"}/bin/${nixCats_packageName} \"%F\"" "${placeholder "out"}/share/applications/${nixCats_packageName}.desktop" ]}
    ''
  + ''
    ${lib.concatMapStringsSep "\n" (alias: "ln -s ${lib.escapeShellArgs [ "${placeholder "out"}/bin/${nixCats_packageName}" "${placeholder "out"}/bin/${alias}" ]}") customAliases}
    ${host_phase}
    ''
  + (let
    manifestWrapperStr = lib.escapeShellArgs [
      "${neovim-unwrapped}/bin/nvim" "${placeholder "out"}/bin/nvim-wrapper"
      "--add-flags" "--cmd ${lib.escapeShellArg "source${placeholder "out"}/${nixCats_packageName}-setup.lua"}"
    ];
  in /* bash */ ''
    echo "Generating remote plugin manifest"
    export NVIM_RPLUGIN_MANIFEST=$out/rplugin.vim
    { [ -e "$manifestLuaPath" ] && cat "$manifestLuaPath" || echo "$manifestLua"; } > ${lib.escapeShellArg "${placeholder "out"}/${nixCats_packageName}-setup.lua"}
    makeWrapper ${manifestWrapperStr} ${wrapperArgsStr}
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
    rm '${placeholder "out"}/bin/nvim-wrapper'
    touch '${placeholder "out"}/rplugin.vim'
    mv '${placeholder "out"}/rplugin.vim' ${lib.escapeShellArg "${placeholder "out"}/${nixCats_packageName}-rplugin.vim"}
  '')
  + (let
    finalArgStr = lib.escapeShellArgs [
      "${neovim-unwrapped}/bin/nvim" "${placeholder "out"}/bin/${nixCats_packageName}"
      "--set" "NVIM_SYSTEM_RPLUGIN_MANIFEST" "${placeholder "out"}/${nixCats_packageName}-rplugin.vim"
      "--set" "NVIM_WRAPPER_PATH_NIX" "${placeholder "out"}/bin/${nixCats_packageName}"
      "--add-flags" "--cmd ${lib.escapeShellArg "source${placeholder "out"}/${nixCats_packageName}-setup.lua"}" ]
      + lib.optionalString (bashBeforeWrapper != "") " --run \"$(addprebash)\"";
  in /* bash */ ''
    # see:
    # https://github.com/NixOS/nixpkgs/issues/318925
    echo "Looking for lua dependencies..."
    source ${neovim-unwrapped.lua}/nix-support/utils.sh || true
    _addToLuaPath '${vimPackDir}' || true
    echo "propagated dependency path for plugins: $LUA_PATH"
    echo "propagated dependency cpath for plugins: $LUA_CPATH"
    { [ -e "$setupLuaPath" ] && cat "$setupLuaPath" || echo "$setupLua"; } > ${lib.escapeShellArg "${placeholder "out"}/${nixCats_packageName}-setup.lua"}
    addprebash() {
      [ -e "$bashBeforeWrapperPath" ] && cat "$bashBeforeWrapperPath" || echo "$bashBeforeWrapper"
    }
    makeWrapper ${finalArgStr} ${wrapperArgsStr} \
        --prefix LUA_PATH ';' "$LUA_PATH" \
        --prefix LUA_CPATH ';' "$LUA_CPATH" \
        --set-default VIMINIT 'lua nixCats.init_main()'

    runHook postBuild
  '');
}
