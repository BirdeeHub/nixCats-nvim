# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
# derived from:
# https://github.com/NixOS/nixpkgs/blob/ae5d2af73efa5e25bf9bf43672cd3d8d99c613d0/pkgs/applications/editors/vim/plugins/vim-utils.nix#L136-L207
{ lib
  , buildEnv
  , writeTextFile
  , runCommand
  , symlinkJoin
  , linkFarm

  , nixCats
  , startup ? []
  , opt ? []
  , packageName ? "myNeovimPackages"
  , grammarPackName ? "myNeovimGrammars"
  , python3Env ? null
  , collate_grammars ? true
  , ...
}: let
  vimFarm = prefix: name: drvs:
    let mkEntryFromDrv = drv: { name = "${prefix}/${lib.getName drv}"; path = drv; };
    in linkFarm name (map mkEntryFromDrv drvs);

  grammarMatcher = yes: builtins.filter (drv: let
    # NOTE: matches if pkgs.neovimUtils.grammarToPlugin was called on it.
    # This only matters for collate_grammars setting and the lazy.nvim wrapper.
    cond = (builtins.match "^vimplugin-treesitter-grammar-.*" "${lib.getName drv}") != null;
    match = if yes then cond else ! cond;
  in
  if drv ? outPath then match else ! yes);

  # a function. I will call it in the altered vimUtils.packDir function below
  # and give it the nixCats plugin function from before and the various resolved dependencies
  # so that I can expose the list of installed packages to lua.
  callNixCats = nixCats:
    {
      ts_grammar_plugin_combined
      , start
      , opt
      , python3link ? null
      , ...
    }:
  let
    inherit (import ../utils/n2l.nix) types;
    # lazy.nvim wrapper uses this value to add the parsers back.
    ts_grammar_path = if collate_grammars then ts_grammar_plugin_combined else
      types.inline-unsafe.mk { body = "vim.g[ [[nixCats-special-rtp-entry-vimPackDir]] ] .. [[/pack/${grammarPackName}/start/*]]"; };

    mkEntryFromDrv = drv: { name = "${lib.getName drv}"; value = drv; };
    fullDeps = {
      allPlugins = {
        start = builtins.listToAttrs (map mkEntryFromDrv start);
        opt = builtins.listToAttrs (map mkEntryFromDrv opt);
        inherit ts_grammar_path;
      };
      python3Path = if (python3link == null) then null
        else ''${python3link}/pack/${packageName}/start/__python3_dependencies/python3'';
    };
    nixCatsDir = nixCatsDRV: (writeTextFile {
      name = "nixCats-special-rtp-entry-nixCats-pathfinder";
      text = ''
        vim.g[ [[nixCats-special-rtp-entry-nixCats]] ] = [[${nixCatsDRV}]]
        return [[${nixCatsDRV}]]
      '';
      executable = false;
      destination = "/lua/nixCats/saveTheCats.lua";
    });
    nixCatsFinal = nixCats fullDeps;
  in # add fully called nixCats plugin along with another to save its path.
  [ nixCatsFinal (nixCatsDir nixCatsFinal) ];

  # filter out all the grammars so we can group them up
  start = grammarMatcher false startup;

  # group them all up so that adding them back when clearing the rtp for lazy isnt painful.
  collected_grammars = grammarMatcher true startup;

  ts_grammar_plugin_combined = symlinkJoin {
    name = "vimplugin-treesitter-grammar-ALL-INCLUDED";
    paths = map (e: e.outPath) collected_grammars;
  };

  packdirGrammar = vimFarm "pack/${grammarPackName}/start" "packdir-grammar" (if collate_grammars then [ ts_grammar_plugin_combined ] else collected_grammars);

  #creates the nixCats plugin from the function definition in builder/default.nix
  resolvedCats = callNixCats nixCats {
    inherit start opt python3link packageName
    python3Env ts_grammar_plugin_combined;
  };

  packdirStart = vimFarm "pack/${packageName}/start" "packdir-start" (start ++ resolvedCats);

  packdirOpt = vimFarm "pack/${packageName}/opt" "packdir-opt" opt;

  # Assemble all python3 dependencies into a single `site-packages` to avoid doing recursive dependency collection
  # for each plugin.
  # This directory is only for python import search path, and will not slow down the startup time.
  # see :help python3-directory for more details
  python3link = if python3Env == null then null else runCommand "vim-python3-deps" {} ''
    mkdir -p $out/pack/${packageName}/start/__python3_dependencies
    ln -s ${python3Env}/${python3Env.sitePackages} $out/pack/${packageName}/start/__python3_dependencies/python3
  '';

in
buildEnv {
  name = "vim-pack-dir";
  paths = [ packdirStart packdirOpt packdirGrammar ] ++ lib.optional (python3link != null) python3link;
  # gather all propagated build inputs from packDir
  postBuild = ''
    mkdir $out/nix-support
    for i in $(find -L $out -name propagated-build-inputs ); do
      cat "$i" >> $out/nix-support/propagated-build-inputs
    done
  '';
}
