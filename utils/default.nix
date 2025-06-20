# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
# NOTE: This file exports the entire public interface for nixCats
with builtins; let lib = import ./lib.nix; in rec {
  /**
    `utils.baseBuilder` is the main builder function of nixCats.

    ## Arguments

    ### **luaPath** (`path` or `stringWithContext`)
    STORE PATH to your `~/.config/nvim` replacement.
    e.g. `./.`

    ### **pkgsParams** (`AttrSet`)
    set of items for building the pkgs that builds your neovim.

    accepted attributes are:

    - `nixpkgs` (`path` | `input` | `channel`)
    : required unless using `pkgs`
    : allows path, or flake input

    - `system` (`string`)
    : required unless using `pkgs`
    : or using --impure argument

    - `pkgs` (`channel`)
    : can be passed instead of `nixpkgs` and `system`
    : the resulting nvim will inherit overlays and other such modifications of the `pkgs` value

    - `dependencyOverlays` (`listOf overlays` | `null`)
    : default = null

    - `extra_pkg_config` (`AttrSet`)
    : default = {}
    : the attrset passed to:
    : `import nixpkgs { config = extra_pkg_config; inherit system; }`

    - `extra_pkg_params` (`AttrSet`)
    : default = {}
    : `import nixpkgs (extra_pkg_params // { inherit system; })`

    - `nixCats_passthru` (`AttrSet`)
    : default = {}
    : attrset of extra stuff for finalPackage.passthru

    ```nix
    { inherit nixpkgs system dependencyOverlays; }
    ```

    ```nix
    { inherit pkgs; }
    ```

    ### **categoryDefinitions** (`functionTo` `AttrSet`)
    type: function that returns set of sets of categories of dependencies.
    Called with the contents of the current package definition as arguments

    ```nix
    { pkgs, settings, categories, extra, name, mkPlugin, ... }@packageDef: {
      lspsAndRuntimeDeps = {
        general = with pkgs; [ ];
      };
      startupPlugins = {
        general = with pkgs.vimPlugins; [ ];
        some_other_name = [];
      };
      # ...
    }
    ```

    see :h [nixCats.flake.outputs.categories](https://nixcats.org/nixCats_format.html#nixCats.flake.outputs.categories)

    ### **packageDefinitions** (`AttrsOf` `functionTo` `AttrSet`)
    set of functions that each represent the settings and included categories for a package.

    Among other info, things declared in settings, categories, and extra will be available in lua.

    ```nix
    {
      nvim = { pkgs, mkPlugin, ... }: {
        settings = {};
        categories = {
          general = true;
          some_other_name = true;
        };
        extra = {};
      };
    }
    ```

    see :h [nixCats.flake.outputs.packageDefinitions](https://nixcats.org/nixCats_format.html#nixCats.flake.outputs.packageDefinitions)

    see :h [nixCats.flake.outputs.settings](https://nixcats.org/nixCats_format.html#nixCats.flake.outputs.settings)

    ### **name** (`string`)
    name of the package to build from `packageDefinitions`

    ## Note:

    When using override, all values shown above will
    be top level attributes of prev, none will be nested.

    i.e. `finalPackage.override (prev: { inherit (prev) dependencyOverlays; })`
    
    NOT `prev.pkgsParams.dependencyOverlays` or something like that

    ---
  */
  baseBuilder = import ../builder { nclib = lib; utils = import ./.; };

  /**
    a set of templates to get you started. See [the template list](https://nixcats.org/nixCats_templates.html).

    ---
  */
  templates = import ../templates;

  /**
    standardPluginOverlay is called with flake inputs or a set of fetched derivations.

    It will extract all items named in the form `plugins-foobar`

    and return an overlay containing those items transformed into neovim plugins.

    After adding the overlay returned, you can access them using `pkgs.neovimPlugins.foobar`

    ## Example

    if you had in your flake inputs
    ```nix
    inputs = {
      plugins-foobar = {
        url = "github:exampleuser/foobar.nvim";
        flake = false;
      };
    };
    ```

    you can put the following in your dependencyOverlays
    ```nix
    dependencyOverlays = [ (standardPluginOverlay inputs) ];
    ```

    and then 
    ```nix
    pkgs.neovimPlugins.foobar
    ```

    ---
  */
  standardPluginOverlay = (import ./autoPluginOverlay.nix).standardPluginOverlay;

  /**
    same as standardPluginOverlay except if you give it `plugins-foo.bar`
    you can `pkgs.neovimPlugins.foo-bar` and still `packadd foo.bar`

    ## Example

    ```nix
    dependencyOverlays = [ (sanitizedPluginOverlay inputs) ];
    ```

    ---
  */
  sanitizedPluginOverlay = (import ./autoPluginOverlay.nix).sanitizedPluginOverlay;

  /**
    if your dependencyOverlays is a list rather than a system-wrapped set,
    to deal with when other people (incorrectly) output an overlay wrapped
    in a system variable you may call this function on it.

    ## Example

    ```nix
    (utils.fixSystemizedOverlay inputs.codeium.overlays
      (system: inputs.codeium.overlays.${system}.default)
    )
    ```    

    ---
  */
  fixSystemizedOverlay = overlaysSet: outfunc:
    (final: prev: if !(overlaysSet ? prev.system) then {}
      else (outfunc prev.system) final prev);

  /**
    takes all the arguments of the main builder function but as a single set,
    except it cannot take `system` or `pkgs`, from pkgsParams, only `nixpkgs`.

    Instead of name it needs defaultPackageName

    This will control the namespace of the generated modules
    as well as the default package name to be enabled if only enable = true is present.

    Unlike in the baseBuilder, arguments are optional,
    but if you want the module to be preloaded with configured packages,
    they are not.

    The module will be able to combine any definitions passed in with new ones defined in the module correctly.

    ## Arguments

    - `defaultPackageName` (`string`)
    : default = null
    : sets the default package to install when module is enabled.
    : if set, by default controls the namespace of the generated module

    - `moduleNamespace` (`listOf string`)
    : default = if `defaultPackageName != null` then `[ defaultPackageName ]` else `[ "nixCats" ]`
    : can be used to override the namespace of the module options,
    : meaning `[ "programs" "nixCats" ]` would create options like `programs.nixCats.enable = true`.

    - `dependencyOverlays` (`listOf overlays` or `null`)
    : default = null

    - `luaPath` (`path` or `stringWithContext`)
    : default = ""
    : store path to your ~/.config/nvim replacement within your nix config.

    - `keepLuaBuilder` (`function`)
    : default = null
    : baseBuilder with luaPath argument applied, can be used instead of luaPath

    - `extra_pkg_config` (`attrs`)
    : default = {}
    : the attrset passed to `import nixpkgs { config = extra_pkg_config; inherit system; }`

    - `extra_pkg_params` (`AttrSet`)
    : default = {}
    : `import nixpkgs (extra_pkg_params // { inherit system; })`

    - `nixpkgs` (`path` or `attrs`)
    : default = null
    : nixpkgs flake input, channel path, or pkgs variable

    - `categoryDefinitions` (`functionTo` `AttrSet`)
    : default = (_:{})
    : same as for the baseBuilder

    - `packageDefinitions` (`AttrsOf` `functionTo` `AttrSet`)
    : default = {}
    : same as for the baseBuilder

    ---
  */
  mkNixosModules = import ./mkModules.nix {
    isHomeManager = false;
    nclib = lib;
    utils = import ./.;
  };

  /**
    takes all the arguments of the main builder function but as a single set,
    except it cannot take `system` or `pkgs`, from pkgsParams, only `nixpkgs`.

    Instead of name it needs defaultPackageName

    This will control the namespace of the generated modules
    as well as the default package name to be enabled if only enable = true is present.

    Unlike in the baseBuilder, arguments are optional,
    but if you want the module to be preloaded with configured packages,
    they are not.

    The module will be able to combine any definitions passed in with new ones defined in the module correctly.

    The generated home manager module is the same as the nixos module

    Except there are no per-user arguments, because the module installs for the home manager user

    ## Arguments

    - `defaultPackageName` (`string`)
    : default = null
    : sets the default package to install when module is enabled.
    : if set, by default controls the namespace of the generated module

    - `moduleNamespace` (`listOf string`)
    : default = if `defaultPackageName != null` then `[ defaultPackageName ]` else `[ "nixCats" ]`
    : can be used to override the namespace of the module options,
    : meaning `[ "programs" "nixCats" ]` would create options like `programs.nixCats.enable = true`.

    - `dependencyOverlays` (`listOf overlays` or `null`)
    : default = null

    - `luaPath` (`path` or `stringWithContext`)
    : default = ""
    : store path to your ~/.config/nvim replacement within your nix config.

    - `keepLuaBuilder` (`function`)
    : default = null
    : baseBuilder with luaPath argument applied, can be used instead of luaPath

    - `extra_pkg_config` (`attrs`)
    : default = {}
    : the attrset passed to `import nixpkgs { config = extra_pkg_config; inherit system; }`

    - `extra_pkg_params` (`AttrSet`)
    : default = {}
    : `import nixpkgs (extra_pkg_params // { inherit system; })`

    - `nixpkgs` (`path` or `attrs`)
    : default = null
    : nixpkgs flake input, channel path, or pkgs variable

    - `categoryDefinitions` (`functionTo` `AttrSet`)
    : default = (_:{})
    : same as for the baseBuilder

    - `packageDefinitions` (`AttrsOf` `functionTo` `AttrSet`)
    : default = {}
    : same as for the baseBuilder

    ---
  */
  mkHomeModules = import ./mkModules.nix {
    isHomeManager = true;
    nclib = lib;
    utils = import ./.;
  };

  /**
    see :h [nixCats.flake.outputs.utils.n2l](https://nixcats.org/nixCats_format.html#nixCats.flake.outputs.utils.n2l)

    you can use this to make values in the tables generated
    for the nixCats plugin using lua literals.

    ```nix
    cache_location = utils.n2l.types.inline-unsafe.mk { body = "vim.fn.stdpath('cache')"; }
    ```

    ---
  */
  n2l = lib.n2l;

  /**
    see `h: nixCats.flake.outputs.utils.n2l`

    ```nix
    utils.mkLuaInline "[[I am a]] .. [[ lua ]] .. type([[value]])";
    ```

    alias for

    ```nix
    body: inline.types.inline-unsafe.mk { inherit body; };
    ```

    ---
  */
  mkLuaInline = lib.n2l.mkLuaInline;

  /**
    `flake-utils.lib.eachSystem` but without the flake input

    Builds a map from `<attr> = value` to `<attr>.<system> = value` for each system

    ## Arguments

    - `systems` (`listOf strings`)

    - `f` (`functionTo` `AttrSet`)

    ---
  */
  eachSystem = systems: f: let
    # get function result and insert system variable
    op = attrs: system: let
      ret = f system;
      op = attrs: key: attrs // {
        ${key} = (attrs.${key} or { })
          // { ${system} = ret.${key}; };
      };
    in foldl' op attrs (attrNames ret);
  # Merge together the outputs for all systems.
  in foldl' op { } (systems ++
    (if builtins ? currentSystem && ! elem builtins.currentSystem systems
    # add the current system if --impure is used
    then [ builtins.currentSystem ]
    else []));

  /**
    in case someone didn't know that genAttrs is great for dealing with the system variable,
    this is literally just nixpkgs.lib.genAttrs

    ## Arguments

    - `systems` (`listOf strings`)

    - `f` (`function`)

    ---
  */
  bySystems = lib.genAttrs;

  /**
    Returns a merged definition from a list of definitions.

    Works with both `categoryDefinitions` and individual `packageDefinitions`

    If "replace" is chosen, it updates anything it finds that isn't another set
    (with head being "older" and tail being "newer")

    If "merge" is chosen, if it encounters a list in both functions,
    (usually representing a category)
    it will merge them together rather than replacing the old one with the new one.

    This means it works slightly differently for environment variables
    because each one will be updated individually rather than at a category level.

    ## Arguments

    - `type` (`enumOf` `"replace" | "merge"`)
    : controls the way individual categories are merged between definitions

    - `definitions` (`listOf` `functionTo` `AttrSet`)
    : accepts a list of `categoryDefinitions` or a list of individual `packageDefinition`

    ---
  */
  mergeDefs = type: definitions:
    args: let
      mergefunc = if type == "replace"
      then lib.pickyRecUpdateUntil {}
      else if type == "merge"
      then lib.recursiveUpdateWithMerge
      else throw ''
        `merged_definition = utils.mergeDefs type [ definitions ];`
        valid values of `type` are: "replace" or "merge"
      '';
    in lib.pipe definitions [
      (map (v: v args))
      (foldl' mergefunc {})
    ];

  /**
    alias for `utils.mergeDefs "replace" [ oldCats newCats ]`
    Works with both `categoryDefinitions` and individual `packageDefinitions`

    ## Arguments

    - `oldCats` (`functionTo` `AttrSet`)
    : accepts `categoryDefinitions` or a single `packageDefinition`

    - `newCats` (`functionTo` `AttrSet`)
    : accepts `categoryDefinitions` or a single `packageDefinition`

    ---
  */
  mergeCatDefs = oldCats: newCats:
    mergeDefs "replace" [ oldCats newCats ];

  /**
    alias for `utils.mergeDefs "merge" [ oldCats newCats ]`
    Works with both `categoryDefinitions` and individual `packageDefinitions`

    ## Arguments

    - `oldCats` (`functionTo` `AttrSet`)
    : accepts `categoryDefinitions` or a single `packageDefinition`

    - `newCats` (`functionTo` `AttrSet`)
    : accepts `categoryDefinitions` or a single `packageDefinition`

    ---
  */
  deepmergeCats = oldCats: newCats:
    mergeDefs "merge" [ oldCats newCats ];

  /**
    makes a default package and then one for each name in `packageDefinitions`

    for constructing flake outputs.

    ## Arguments
    
    - `finalBuilder` (`function`)
    : this is `baseBuilder` with all arguments except `name` applied.

    - `packageDefinitions` (`AttrSet`)
    : the set of `packageDefinitions` passed to the builder, passed in again.

    - `defaultName` (`string`)
    : the name of the package to be output as default in the resulting set of packages.

    ---
  */
  mkPackages = finalBuilder: packageDefinitions: defaultName:
    { default = finalBuilder defaultName; }
    // mkExtraPackages finalBuilder packageDefinitions;

  /**
    `mkPackages` but without adding a default package, or the final `defaultName` argument

    ## Arguments
    
    - `finalBuilder` (`function`)
    : this is `baseBuilder` with all arguments except `name` applied.

    - `packageDefinitions` (`AttrSet`)
    : the set of `packageDefinitions` passed to the builder, passed in again.

    ---
  */
  mkExtraPackages = finalBuilder: packageDefinitions:
  (mapAttrs (name: _: finalBuilder name) packageDefinitions);

  /**
    like mkPackages but easier.

    Pass it a package and it will make that the default, and build all the packages
    in the packageDefinitions that package was built with.

    ## Arguments

    - `package` (`NixCats nvim derivation`)

    ---
  */
  mkAllWithDefault = package:
  { default = package; } // (mkAllPackages package);

  /**
    like `mkExtraPackages` but easier.

    Pass it a package and it will build all the packages
    in the `packageDefinitions` that package was built with.

    ## Arguments

    - `package` (`NixCats nvim derivation`)

    ---
  */
  mkAllPackages = package: lib.pipe package.passthru.packageDefinitions [
    attrNames
    (map (name: lib.nameValuePair name (package.overrideNixCats { inherit name; })))
    listToAttrs
  ];

  /**
    makes a set of overlays from your definitions for exporting from a flake.

    defaultName is the package name for the default overlay

    ## Arguments

    - `luaPath` (`function` or `stringWithContext`)

    - `pkgsParams` (`AttrSet`)
    : exactly the same as the `pkgsParams` in `baseBuilder`
    : except without `system`

    - `categoryDefinitions` (`FunctionTo` `AttrSet`)
    : exactly the same as `categoryDefinitions` in `baseBuilder`

    - `packageDefinitions` (`AttrSet` `functionTo` `AttrSet`)
    : exactly the same as `packageDefinitions` in `baseBuilder`

    - `defaultName` (`string`)

    ---
  */
  makeOverlays = 
    luaPath:
    {
      nixpkgs
      , extra_pkg_config ? {}
      , dependencyOverlays ? null
      , nixCats_passthru ? {}
      , ...
    }@pkgsParams:
    categoryDefFunction:
    packageDefinitions: defaultName: let
      keepLuaBuilder = if isFunction luaPath then luaPath else baseBuilder luaPath;
      makeOverlay = name: final: prev: {
        ${name} = keepLuaBuilder (pkgsParams // { inherit (final) system; }) categoryDefFunction packageDefinitions name;
      };
      overlays = (mapAttrs (name: _: makeOverlay name) packageDefinitions) // { default = (makeOverlay defaultName); };
    in overlays;

  /**
    makes a set of overlays from your definitions for exporting from a flake.

    Differs from `makeOverlays` in that the default overlay is a set of all the packages

    default overlay yeilds `pkgs.${defaultName}.${packageName}` with all the packages

    ## Arguments

    - `luaPath` (`function` or `stringWithContext`)

    - `pkgsParams` (`AttrSet`)
    : exactly the same as the `pkgsParams` in `baseBuilder`
    : except without `system`

    - `categoryDefinitions` (`FunctionTo` `AttrSet`)
    : exactly the same as `categoryDefinitions` in `baseBuilder`

    - `packageDefinitions` (`AttrSet` `functionTo` `AttrSet`)
    : exactly the same as `packageDefinitions` in `baseBuilder`

    - `defaultName` (`string`)

    ---
  */
  makeOverlaysWithMultiDefault = 
    luaPath:
    {
      nixpkgs
      , extra_pkg_config ? {}
      , dependencyOverlays ? null
      , nixCats_passthru ? {}
      , ...
    }@pkgsParams:
    categoryDefFunction:
    packageDefinitions: defaultName: let
      keepLuaBuilder = if isFunction luaPath then luaPath else baseBuilder luaPath;
      makeOverlay = name: final: prev: {
        ${name} = keepLuaBuilder (pkgsParams // { inherit (final) system; }) categoryDefFunction packageDefinitions name;
      };
      overlays = (mapAttrs (name: _: makeOverlay name) packageDefinitions) // {
        default = (makeMultiOverlay luaPath pkgsParams categoryDefFunction packageDefinitions defaultName (attrNames packageDefinitions));
      };
    in overlays;

  /**
    makes a set of overlays from your definitions for exporting from a flake.

    overlay yeilds `pkgs.${importName}.${packageName}`

    contains all the packages named in `namesIncList` (the last argument)

    ## Arguments

    - `luaPath` (`function` or `stringWithContext`)

    - `pkgsParams` (`AttrSet`)
    : exactly the same as the `pkgsParams` in `baseBuilder`
    : except without `system`

    - `categoryDefinitions` (`FunctionTo` `AttrSet`)
    : exactly the same as `categoryDefinitions` in `baseBuilder`

    - `packageDefinitions` (`AttrSet` `functionTo` `AttrSet`)
    : exactly the same as `packageDefinitions` in `baseBuilder`

    - `importName` (`string`)
    : when applied, overlay yeilds `pkgs.${importName}.${packageName}`

    - `namesIncList` (`listOf` `string`)
    : the names of packages to include in the set yeilded by the overlay

    ---
  */
  makeMultiOverlay = luaPath:
    {
      nixpkgs
      , extra_pkg_config ? {}
      , dependencyOverlays ? null
      , nixCats_passthru ? {}
      , ...
    }@pkgsParams:
    categoryDefFunction:
    packageDefinitions:
    importName:
    namesIncList:
    (final: prev: {
      ${importName} = listToAttrs (
        map
          (name: let
            keepLuaBuilder = if isFunction luaPath then luaPath else baseBuilder luaPath;
          in
            {
              inherit name;
              value =  keepLuaBuilder (pkgsParams // { inherit (final) system; }) categoryDefFunction packageDefinitions name;
            }
          ) namesIncList
        );
      }
    );

  /**
    `makeMultiOverlay` except it takes only 2 arguments.

    ## Arguments

    - `package` (`NixCats nvim derivation`)
    : will include all packages in the `packageDefinitions` the package was built with

    - `importName` (`string`)
    : overlay will yield `pkgs.${importName}.${packageName}`

    ## Example

    ```nix
    easyMultiOverlayNamespaced self.packages.x86_64-linux.${packageName} packageName
    # The `system` chosen DOES NOT MATTER.
    # The overlay utilizes override to change it to match `prev.system`
    ```

    ---
  */
  easyMultiOverlayNamespaced = package: importName: let
    allnames = attrNames package.passthru.packageDefinitions;
  in
  (final: prev: {
    ${importName} = listToAttrs (map (name:
        lib.nameValuePair name (package.overrideNixCats { inherit name; inherit (prev) system; })
      ) allnames);
  });

  /**
    makes a single overlay with all the packages
    in `packageDefinitions` from the package as `pkgs.${packageName}`

    ## Arguments

    - `package` (`NixCats nvim derivation`)
    : will include all packages in the `packageDefinitions` the package was built with

    ## Example

    ```nix
    easyMultiOverlay self.packages.x86_64-linux.${packageName}
    # The `system` chosen DOES NOT MATTER.
    # The overlay utilizes override to change it to match `prev.system`
    ```

    ---
  */
  easyMultiOverlay = package: let
    allnames = attrNames package.passthru.packageDefinitions;
  in
  (final: prev: listToAttrs (map (name:
    lib.nameValuePair name (package.overrideNixCats { inherit name; inherit (prev) system; })
  ) allnames));

  /**
    makes a separate overlay for each of the packages
    in `packageDefinitions` from the package as `pkgs.${packageName}`

    ## Arguments

    - `package` (`NixCats nvim derivation`)
    : will include all packages in the `packageDefinitions` the package was built with

    ## Example

    ```nix
    easyMultiOverlay self.packages.x86_64-linux.${packageName}
    # The `system` chosen DOES NOT MATTER.
    # The overlay utilizes override to change it to match `prev.system`
    ```

    ---
  */
  easyNamedOvers = package: let
    mapfunc = map (name:
      lib.nameValuePair name (final: prev: {
        ${name} = package.overrideNixCats { inherit (prev) system; };
      }));
  in lib.pipe package.passthru.packageDefinitions [
    attrNames
    mapfunc
    listToAttrs
  ];

}
