{ lib, stdenv, vim, vimPlugins, buildEnv, writeText, writeTextFile
  , runCommand, makeWrapper
  , python3
  , callPackage, makeSetupHook
  , linkFarm
  , vimUtils
}: let
  transitiveClosure = plugin:
    [ plugin ] ++ (
      lib.unique (builtins.concatLists (map transitiveClosure plugin.dependencies or []))
    );

  findDependenciesRecursively = plugins: lib.concatMap transitiveClosure plugins;

  callNixCats = nixCats:
    {
      treesitter_grammars
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
        inherit startPlugins treesitter_grammars;
        opt = builtins.listToAttrs (map mkEntryFromDrv opt);
      };
      python3Path = if (allPython3Dependencies python3.pkgs == [])
        then null
        else ''${python3link}/pack/${packageName}/start/__python3_dependencies/python3'';
    };
  in
  nixCats fullDeps;

  nixCatsDir = nixCats: writeTextFile {
    name = "nixCats-special-rtp-entry-nixCats-pathfinder";
    text = ''
        vim.g[ [[nixCats-special-rtp-entry-nixCats]] ] = [[ ${nixCats} ]]
    '';
    executable = false;
    destination = "/lua/nixCats/saveTheCats.lua";
  };

  vimFarm = prefix: name: drvs:
    let mkEntryFromDrv = drv: { name = "${prefix}/${lib.getName drv}"; path = drv; };
    in linkFarm name (map mkEntryFromDrv drvs);

  packDir =  nixCats: packages:
  let
    packageLinks = withGrammar: packageName: {start ? [], opt ? []}:
    let
      # `nativeImpl` expects packages to be derivations, not strings (as
      # opposed to older implementations that have to maintain backwards
      # compatibility). Therefore we don't need to deal with "knownPlugins"
      # and can simply pass `null`.
      depsOfOptionalPlugins = lib.subtractLists opt (findDependenciesRecursively opt);
      startWithDeps = findDependenciesRecursively start;
      allPlugins = lib.unique (startWithDeps ++ depsOfOptionalPlugins);

      mkEntryFromDrv = drv: { name = "${lib.getName drv}"; value = drv; };

      allPluginsMapped = (map mkEntryFromDrv allPlugins);

      grammarMatcher = entry: 
        (if entry != null && entry.name != null then 
          (if (builtins.match "^vimplugin-treesitter-grammar-.*" entry.name) != null
          then true else false)
        else false);

      treesitter_grammars = builtins.listToAttrs 
        (builtins.filter (entry: grammarMatcher entry) allPluginsMapped);

      startPlugins = builtins.listToAttrs
        (builtins.filter (entry: ! (grammarMatcher entry)) allPluginsMapped);

      allPython3Dependencies = ps:
        lib.flatten (builtins.map (plugin: (plugin.python3Dependencies or (_: [])) ps) allPlugins);
      python3Env = python3.withPackages allPython3Dependencies;

      resolvedCats = callNixCats nixCats {
          inherit treesitter_grammars startPlugins opt
          python3link packageName allPython3Dependencies;
        };

      packdirStart = vimFarm "pack/${packageName}/start" "packdir-start"
            ( (builtins.attrValues startPlugins) ++ [ resolvedCats (nixCatsDir resolvedCats) ]);
      grammarDirStart = vimFarm "pack/GrammarsFor${packageName}/start" "packdir-start"
            (builtins.attrValues treesitter_grammars);
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
    if withGrammar then [ grammarDirStart ] else
      [ packdirStart packdirOpt ] ++ lib.optional (allPython3Dependencies python3.pkgs != []) python3link;
  in {
    vim-pack-dir = buildEnv {
      name = "vim-pack-dir";
      paths = (lib.flatten (lib.mapAttrsToList (packageLinks false) packages));
    };
    vim-grammar-dir = buildEnv {
      name = "vim-grammar-dir";
      paths = (lib.flatten (lib.mapAttrsToList (packageLinks true) packages));
    };
  };
in {
  inherit packDir;
}
