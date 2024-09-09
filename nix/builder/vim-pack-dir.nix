# derived from:
# https://github.com/NixOS/nixpkgs/blob/ae5d2af73efa5e25bf9bf43672cd3d8d99c613d0/pkgs/applications/editors/vim/plugins/vim-utils.nix#L136-L207
{ lib, stdenv, buildEnv, writeText, writeTextFile
  , runCommand
  , python3
  , linkFarm
}: let
  # NOTE: define helpers for packDir function here:

  # TODO: ?
  # https://github.com/NixOS/nixpkgs/issues/332580#issuecomment-2307253021
  # if nvim-treesitter stops vendoring in queries,
  # make isOldGrammarType check nixpkgs version of when that occurred
  isOldGrammarType = true;

  grammarPackName = "myNeovimGrammars";

  grammarMatcher = yes: builtins.filter (drv: let
    # if we get to split them up, we can include even if not a dir
    new = drv: builtins.pathExists "${drv.outPath}/parser" && "${lib.getName drv}" != "nvim-treesitter";
    old = drv: lib.pathIsDirectory "${drv.outPath}/parser" && "${lib.getName drv}" != "nvim-treesitter";
    cond = ! isOldGrammarType && new drv || old drv;
    match = if yes then cond else ! cond;
  in
  if drv ? outPath then match else ! yes);

  # a function. I will call it in the altered vimUtils.packDir function below
  # and give it the nixCats plugin function from before and the various resolved dependencies
  # so that I can expose the list of installed packages to lua.
  callNixCats = nixCats:
    {
      ts_grammar_plugin_combined
      , startPlugins
      , opt
      , python3link
      , packageName
      , allPython3Dependencies
      , ...
    }:
  let
    inherit (import ./ncTools.nix) mkLuaInline;
    # lazy.nvim wrapper uses this value to add the parsers back.
    ts_grammar_path = if isOldGrammarType then ts_grammar_plugin_combined else
      mkLuaInline "vim.g[ [[nixCats-special-rtp-entry-vimPackDir]] ] .. [[/pack/${grammarPackName}/start/*]]";

    mkEntryFromDrv = drv: { name = "${lib.getName drv}"; value = drv; };
    fullDeps = {
      allPlugins = {
        start = builtins.listToAttrs (map mkEntryFromDrv startPlugins);
        opt = builtins.listToAttrs (map mkEntryFromDrv opt);
        inherit ts_grammar_path;
        ts_grammar_plugin = ts_grammar_path;
      };
      python3Path = if (allPython3Dependencies python3.pkgs == []) then null
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
  in # we add the plugin with ALL the parsers if its the old way, if its the new way, it will be in our packpath already
  [ nixCatsFinal (nixCatsDir nixCatsFinal) ] ++ (lib.optionals isOldGrammarType [ ts_grammar_plugin_combined ]);

  # gets plugin.dependencies from
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vim/plugins/overrides.nix
  findDependenciesRecursively = plugins: lib.concatMap transitiveClosure plugins;
  transitiveClosure = plugin:
    [ plugin ] ++ (
      lib.unique (builtins.concatLists (map transitiveClosure plugin.dependencies or []))
    );

  vimFarm = prefix: name: drvs:
    let mkEntryFromDrv = drv: { name = "${prefix}/${lib.getName drv}"; path = drv; };
    in linkFarm name (map mkEntryFromDrv drvs);

in


# recieves the nixCats plugin FUNCTION from builder/default.nix as the first argument
# then the normal packages = { start ? [], opt ? [] }
# argument to neovimUtils.packDir as the second argument
nixCats: packages: let

  packageLinks = packageName: {start ? [], opt ? []}: let
    # get dependencies of plugins
    depsOfOptionalPlugins = lib.subtractLists opt (findDependenciesRecursively opt);
    startWithDeps = findDependenciesRecursively start;

    allPlugins = lib.unique (startWithDeps ++ depsOfOptionalPlugins);

    allPython3Dependencies = ps:
      lib.flatten (builtins.map (plugin: (plugin.python3Dependencies or (_: [])) ps) allPlugins);
    python3Env = python3.withPackages allPython3Dependencies;

    # filter out all the grammars so we can group them up
    startPlugins = grammarMatcher false allPlugins;

    # group them all up so that adding them back when clearing the rtp for lazy isnt painful.
    collected_grammars = grammarMatcher true allPlugins;
    # currently nvim-treesitter vendors queries in SOMEHOW
    # It ALSO copies them now, so, we actually HAVE to remove them,
    # because otherwise we get errors....
    ts_grammar_plugin_combined = with builtins; stdenv.mkDerivation (let 
      # so we make a single plugin with them
      treesitter_grammars = map (e: e.outPath) collected_grammars;

      builderLines = map (grmr: /* bash */''
        cp -f -L ${grmr}/parser/*.so $out/parser
      '') treesitter_grammars;

      builderText = (/* bash */''
        #!/usr/bin/env bash
        source $stdenv/setup
        mkdir -p $out/parser
      '') + (concatStringsSep "\n" builderLines);

    in {
      name = "vimplugin-treesitter-grammar-ALL-INCLUDED";
      builder = writeText "builder.sh" builderText;
    });
    # if the queries stop appearing from nowhere, group them like this instead.
    packdirGrammar = lib.optionals (! isOldGrammarType) [
      (vimFarm "pack/${grammarPackName}/start" "packdir-grammar" collected_grammars)
    ];

    #creates the nixCats plugin from the function definition in builder/default.nix
    resolvedCats = callNixCats nixCats {
      inherit startPlugins opt python3link packageName
      allPython3Dependencies ts_grammar_plugin_combined;
    };

    packdirStart = vimFarm "pack/${packageName}/start" "packdir-start" (startPlugins ++ resolvedCats);

    packdirOpt = vimFarm "pack/${packageName}/opt" "packdir-opt" opt;

    # Assemble all python3 dependencies into a single `site-packages` to avoid doing recursive dependency collection
    # for each plugin.
    # This directory is only for python import search path, and will not slow down the startup time.
    # see :help python3-directory for more details
    python3link = runCommand "vim-python3-deps" {} ''
      mkdir -p $out/pack/${packageName}/start/__python3_dependencies
      ln -s ${python3Env}/${python3Env.sitePackages} $out/pack/${packageName}/start/__python3_dependencies/python3
    '';
  in
    [ packdirStart packdirOpt ] ++ packdirGrammar ++ lib.optional (allPython3Dependencies python3.pkgs != []) python3link;

in
buildEnv {
  name = "vim-pack-dir";
  paths = (lib.flatten (lib.mapAttrsToList packageLinks packages));
  # gather all propagated build inputs from packDir
  postBuild = ''
    mkdir $out/nix-support
    for i in $(find -L $out -name propagated-build-inputs ); do
      cat "$i" >> $out/nix-support/propagated-build-inputs
    done
  '';
}
