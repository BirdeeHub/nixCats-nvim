# derived from:
# https://github.com/NixOS/nixpkgs/blob/ae5d2af73efa5e25bf9bf43672cd3d8d99c613d0/pkgs/applications/editors/vim/plugins/vim-utils.nix#L136-L207
{ lib, stdenv, buildEnv, writeText, writeTextFile
  , runCommand
  , python3
  , linkFarm
}: let
  transitiveClosure = plugin:
    [ plugin ] ++ (
      lib.unique (builtins.concatLists (map transitiveClosure plugin.dependencies or []))
    );
  # gets plugin.dependencies from
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vim/plugins/overrides.nix

  findDependenciesRecursively = plugins: lib.concatMap transitiveClosure plugins;

  # TODO: ?
  # https://github.com/NixOS/nixpkgs/issues/332580#issuecomment-2307253021
  # if nvim-treesitter stops vendoring in queries,
  # make isOldGrammarType check nixpkgs version of when that occurred
  isOldGrammarType = true;

  grammarPackName = "myNeovimGrammars";

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
    mkEntryFromDrv = drv: { name = "${lib.getName drv}"; value = drv; };
    ts_grammar_path = if isOldGrammarType then ts_grammar_plugin_combined else
      "]] .. vim.g[ [[nixCats-special-rtp-entry-vimPackDir]] ] .. [[/pack/${grammarPackName}/start/*";
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
  in
  [ nixCatsFinal (nixCatsDir nixCatsFinal) ] ++ (lib.optionals isOldGrammarType [ ts_grammar_path ]);


  vimFarm = prefix: name: drvs:
    let mkEntryFromDrv = drv: { name = "${prefix}/${lib.getName drv}"; path = drv; };
    in linkFarm name (map mkEntryFromDrv drvs);

  packDir =  nixCats: packages:
  let
    packageLinks = packageName: {start ? [], opt ? []}:
    let
      depsOfOptionalPlugins = lib.subtractLists opt (findDependenciesRecursively opt);
      startWithDeps = findDependenciesRecursively start;
      allPlugins = lib.unique (startWithDeps ++ depsOfOptionalPlugins);

      grammarMatcher = yes: builtins.filter (drv: let
        # cond = (builtins.match "vimplugin-treesitter-grammar.*" "${lib.getName drv}") != null;
        new = drv: builtins.pathExists "${drv.outPath}/parser";
        old = drv: lib.pathIsDirectory "${drv.outPath}/parser";
        cond = ! isOldGrammarType && new drv || old drv;
        match = if yes then cond else ! cond;
      in
      if drv ? outPath then match else ! yes);

      collected_grammars = grammarMatcher true allPlugins;

      # group them all up so that adding them back when clearing the rtp for lazy isnt painful.
      ts_grammar_plugin = with builtins; stdenv.mkDerivation (let 
        treesitter_grammars = map (e: e.outPath) collected_grammars;

        builderLines = map (grmr: /* bash */''
          cp -v -f -L ${grmr}/parser/*.so $out/parser
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

      startPlugins = grammarMatcher false allPlugins;

      allPython3Dependencies = ps:
        lib.flatten (builtins.map (plugin: (plugin.python3Dependencies or (_: [])) ps) allPlugins);
      python3Env = python3.withPackages allPython3Dependencies;

      # call the function, creating the nixCats plugin (definition in builder/default.nix)
      resolvedCats = callNixCats nixCats {
        ts_grammar_plugin_combined = ts_grammar_plugin;
        inherit startPlugins opt python3link packageName
        allPython3Dependencies;
      };

      packdirStart = vimFarm "pack/${packageName}/start" "packdir-start" (startPlugins ++ resolvedCats);

      packdirGrammar = lib.optionals (! isOldGrammarType) [
        (vimFarm "pack/${grammarPackName}/start" "packdir-grammar" collected_grammars)
      ];

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
  };

in packDir
