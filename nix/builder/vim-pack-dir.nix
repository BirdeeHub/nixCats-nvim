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

  # a function. I will call it in the altered vimUtils.packDir function below
  # and give it the nixCats plugin function from before and .the various resolved dependencies
  # so that I can expose the list of installed packages to lua.
  callNixCats = nixCats:
    {
      ts_grammar_plugin
      , startPlugins
      , opt
      , python3link
      , packageName
      , allPython3Dependencies
      , ...
    }:
  let
    mkEntryFromDrv = drv: { name = "${lib.getName drv}"; value = drv; };
    fullDeps = {
      allPlugins = {
        start = startPlugins;
        inherit ts_grammar_plugin;
        opt = builtins.listToAttrs (map mkEntryFromDrv opt);
      };
      python3Path = if (allPython3Dependencies python3.pkgs == [])
        then null
        else ''${python3link}/pack/${packageName}/start/__python3_dependencies/python3'';
    };
    nixCatsDir = nixCatsDRV: (writeTextFile {
      name = "nixCats-special-rtp-entry-nixCats-pathfinder";
      text = /* lua */''
          vim.g[ [[nixCats-special-rtp-entry-nixCats]] ] = [[${nixCatsDRV}]]
      '';
      executable = false;
      destination = "/lua/nixCats/saveTheCats.lua";
    });
    nixCatsFinal = nixCats fullDeps;
  in
  [ nixCatsFinal (nixCatsDir nixCatsFinal) ts_grammar_plugin ];


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

      mkEntryFromDrv = drv: { name = "${lib.getName drv}"; value = drv; };

      allPluginsMapped = (map mkEntryFromDrv allPlugins);

      # apparently this is ACTUALLY the standard. Yeah. Strings XD
      # If its stable enough for nixpkgs I guess I can use it here.
      grammarMatcher = entry: 
        (if entry != null && entry.name != null then 
          (if (builtins.match "^vimplugin-treesitter-grammar-.*" entry.name) != null
          then true else false)
        else false);

      # group them all up so that adding them back when clearing the rtp for lazy isnt painful.
      ts_grammar_plugin = with builtins; stdenv.mkDerivation (let 
        treesitter_grammars = (map (entry: entry.value)
          (filter (entry: grammarMatcher entry) allPluginsMapped));

        builderLines = map (grmr: /* bash */''
          cp --no-dereference ${grmr}/parser/*.so $out/parser
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

      startPlugins = builtins.listToAttrs
        (builtins.filter (entry: ! (grammarMatcher entry)) allPluginsMapped);

      allPython3Dependencies = ps:
        lib.flatten (builtins.map (plugin: (plugin.python3Dependencies or (_: [])) ps) allPlugins);
      python3Env = python3.withPackages allPython3Dependencies;

      # call the function, creating the nixCats plugin (definition in builder/default.nix)
      resolvedCats = callNixCats nixCats {
        inherit ts_grammar_plugin startPlugins opt
        python3link packageName allPython3Dependencies;
      };

      packdirStart = vimFarm "pack/${packageName}/start" "packdir-start"
            ( (builtins.attrValues startPlugins) ++ resolvedCats);

      # ok thats kinda all I changed.

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
      [ packdirStart packdirOpt ] ++ lib.optional (allPython3Dependencies python3.pkgs != []) python3link;
  in
  buildEnv {
    name = "vim-pack-dir";
    paths = (lib.flatten (lib.mapAttrsToList packageLinks packages));
    postBuild = ''
      mkdir $out/nix-support
      for i in $(find -L $out -name propagated-build-inputs ); do
        cat "$i" >> $out/nix-support/propagated-build-inputs
      done
    '';
  };

in {
  inherit packDir;
}
