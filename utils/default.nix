# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
# NOTE: This file exports the entire public interface for nixCats
with builtins; let lib = import ./lib.nix; in rec {
  /**
  ---

    `utils.baseBuilder` is the main builder function of nixCats.

    ## Arguments

    ### **luaPath** (`path` or `stringWithContext`)
    STORE PATH to your `~/.config/nvim` replacement.

    ### **pkgsParams** (`AttrSet`)
    set of items for building the pkgs that builds your neovim.

    accepted attributes are:

    - `nixpkgs` (`path` | `input` | `channel`)
    : required. allows path, input, or channel
    : channel means a resolved pkgs variable
    : will not grab overlays from pkgs type variable
    : if passing overlays is desired, put pkgs.overlays into `dependencyOverlays`

    - `system` (`string`)
    : required unless nixpkgs is a resolved channel
    : or using --impure argument

    - `dependencyOverlays` (`listOf overlays` | `attrsOf (listOf overlays)` | `null`)
    : default = null

    - `extra_pkg_config` (`AttrSet`)
    : default = {}
    : the attrset passed to:
    : `import nixpkgs { config = extra_pkg_config; inherit system; }`

    - `nixCats_passthru` (`AttrSet`)
    : default = {}
    : attrset of extra stuff for finalPackage.passthru

    ### **categoryDefinitions** (`functionTo` `AttrSet`)
    type: function that returns set of sets of categories of dependencies.
    Called with the contents of the current package definition as arguments

    ```nix
    categoryDefinitions = { pkgs, settings, categories, extra, name, mkNvimPlugin, ... }@packageDef: {
      lspsAndRuntimeDeps = {
        general = with pkgs; [ ];
      };
      startupPlugins = {
        general = with pkgs.vimPlugins; [ ];
      };
      # ...
    }
    ```

    see :h [nixCats.flake.outputs.categories](https://nixcats.org/nixCats_format.html#nixCats.flake.outputs.categories)

    ### **packageDefinitions** (`AttrsOf` `functionTo` `AttrSet`)
    set of functions that each represent the settings and included categories for a package.

    ```nix
    {
      nvim = { pkgs, mkNvimPlugin, ... }: {
        settings = {};
        categories = {};
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
  baseBuilder =
    luaPath:
    {
      nixpkgs
      , system ? (nixpkgs.system or builtins.system or import ../builder/builder_error.nix)
      , extra_pkg_config ? {}
      , dependencyOverlays ? null
      , nixCats_passthru ? {}
      , ...
    }:
    categoryDefinitions:
    packageDefinitions: name: let
      # validate channel, regardless of its type
      # normalize to something that has lib and outPath in it
      # so that overriders can always use it as expected
      isPkgs = nixpkgs ? path && nixpkgs ? lib && nixpkgs ? config && nixpkgs ? system;
      isNixpkgs = nixpkgs ? lib && nixpkgs ? outPath;
      nixpkgspath = nixpkgs.path or nixpkgs.outPath or nixpkgs;
      newnixpkgs = if isPkgs then nixpkgs // { outPath = nixpkgspath; }
        else if isNixpkgs then nixpkgs
        else {
          lib = nixpkgs.lib or import "${nixpkgspath}/lib";
          outPath = nixpkgspath;
        };
    in
    newnixpkgs.lib.makeOverridable (import ../builder) {
      nixpkgs = newnixpkgs;
      inherit luaPath categoryDefinitions packageDefinitions name
      system extra_pkg_config dependencyOverlays nixCats_passthru;
    };

  /**
    ---

    a set of templates to get you started. See [the template list](https://nixcats.org/nixCats_templates.html).

    ---
  */
  templates = import ../templates;

  /**
    ---

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
    ---

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
    ---

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
    ---

    takes all the arguments of the main builder function but as a single set

    Instead of name it needs defaultPackageName

    This will control the namespace of the generated modules
    as well as the default package name to be enabled if only enable = true is present.

    Unlike in the baseBuilder, all other arguments are optional

    But if you want the module to actually contain configured packages, they are not optional.

    The module will be able to combine any definitions passed in with new ones defined in the module correctly.

    ## Arguments

    `defaultPackageName` (`string`)
    : the only truly required argument
    : by default controls the namespace of the generated module and the default package installed

    `moduleNamespace` (`listOf string`)
    : can be used to override the namespace of the module options
    : `[ "programs" "nixCats" ]` would mean options like `programs.nixCats.enable = true`

    `dependencyOverlays` (`listOf overlays` or `attrsOf (listOf overlays)` or `null`)
    : default = null

    `luaPath` (`path` or `stringWithContext`)
    : default = ""
    : store path to your ~/.config/nvim replacement within your nix config.

    `keepLuaBuilder` (`function`)
    : default = null
    : baseBuilder with luaPath argument applied, can be used instead of luaPath

    `extra_pkg_config` (`attrs`)
    : default = {}
    : the attrset passed to `import nixpkgs { config = extra_pkg_config; inherit system; }`

    `nixpkgs` (`path` or `attrs`)
    : default = null
    : nixpkgs flake input, channel path, or pkgs variable

    `categoryDefinitions` (`functionTo` `AttrSet`)
    : default = (_:{})
    : same as for the baseBuilder

    `packageDefinitions` (`AttrsOf` `functionTo` `AttrSet`)
    : default = {}
    : same as for the baseBuilder

    ---
  */
  mkNixosModules = {
    dependencyOverlays ? null
    , luaPath ? ""
    , keepLuaBuilder ? null
    , categoryDefinitions ? (_:{})
    , packageDefinitions ? {}
    , defaultPackageName
    , moduleNamespace ? [ defaultPackageName ]
    , nixpkgs ? null
    , extra_pkg_config ? {}
    , ... }:
    (import ./mkModules.nix {
      isHomeManager = false;
      oldDependencyOverlays = dependencyOverlays;
      nclib = lib;
      utils = import ./.;
      inherit nixpkgs luaPath keepLuaBuilder categoryDefinitions
        packageDefinitions defaultPackageName extra_pkg_config moduleNamespace;
    });

  /**
    ---

    takes all the arguments of the main builder function but as a single set

    Instead of name it needs defaultPackageName

    This will control the namespace of the generated modules
    as well as the default package name to be enabled if only enable = true is present.

    Unlike in the baseBuilder, all other arguments are optional

    But if you want the module to actually contain configured packages, they are not optional.

    The module will be able to combine any definitions passed in with new ones defined in the module correctly.

    The generated home manager module is the same as the nixos module

    Except there are no per-user arguments, because the module installs for the home manager user

    ## Arguments

    `defaultPackageName` (`string`)
    : the only truly required argument
    : by default controls the namespace of the generated module and the default package installed

    `moduleNamespace` (`listOf string`)
    : can be used to override the namespace of the module options
    : `[ "programs" "nixCats" ]` would mean options like `programs.nixCats.enable = true`

    `dependencyOverlays` (`listOf overlays` or `attrsOf (listOf overlays)` or `null`)
    : default = null

    `luaPath` (`path` or `stringWithContext`)
    : default = ""
    : store path to your ~/.config/nvim replacement within your nix config.

    `keepLuaBuilder` (`function`)
    : default = null
    : baseBuilder with luaPath argument applied, can be used instead of luaPath

    `extra_pkg_config` (`attrs`)
    : default = {}
    : the attrset passed to `import nixpkgs { config = extra_pkg_config; inherit system; }`

    `nixpkgs` (`path` or `attrs`)
    : default = null
    : nixpkgs flake input, channel path, or pkgs variable

    `categoryDefinitions` (`functionTo` `AttrSet`)
    : default = (_:{})
    : same as for the baseBuilder

    `packageDefinitions` (`AttrsOf` `functionTo` `AttrSet`)
    : default = {}
    : same as for the baseBuilder

    ---
  */
  mkHomeModules = {
    dependencyOverlays ? null
    , luaPath ? ""
    , keepLuaBuilder ? null
    , categoryDefinitions ? (_:{})
    , packageDefinitions ? {}
    , defaultPackageName
    , moduleNamespace ? [ defaultPackageName ]
    , nixpkgs ? null
    , extra_pkg_config ? {}
    , ... }:
    (import ./mkModules.nix {
      isHomeManager = true;
      oldDependencyOverlays = dependencyOverlays;
      nclib = lib;
      utils = import ./.;
      inherit nixpkgs luaPath keepLuaBuilder categoryDefinitions
        packageDefinitions defaultPackageName extra_pkg_config moduleNamespace;
    });

  /**
    ---

    see :h [nixCats.flake.outputs.utils.n2l](https://nixcats.org/nixCats_format.html#nixCats.flake.outputs.utils.n2l)

    you can use this to make values in the tables generated
    for the nixCats plugin using lua literals.

    ```nix
    cache_location = utils.n2l.types.inline-safe.mk "vim.fn.stdpath('cache')",
    ```

    ---
  */
  n2l = lib.n2l;

  /**
    ---

    see `h: nixCats.flake.outputs.utils.n2l`

    This is an alias for `utils.n2l.types.inline-safe.mk`

    ---
  */
  mkLuaInline = lib.n2l.types.inline-safe.mk;

  /**
    ---

    `flake-utils.lib.eachSystem` but without the flake input

    Builds a map from `<attr> = value` to `<attr>.<system> = value` for each system

    ## Arguments

    `systems` (`listOf strings`)

    `f` (`functionTo` `AttrSet`)

    ---
  */
  eachSystem = systems: f: let
    # Merge together the outputs for all systems.
    op = attrs: system: let
      ret = f system;
      op = attrs: key: attrs //
          {
            ${key} = (attrs.${key} or { })
              // { ${system} = ret.${key}; };
          }
      ;
    in foldl' op attrs (attrNames ret);
  in foldl' op { } (systems
    ++ # add the current system if --impure is used
      (if builtins ? currentSystem then
         if elem currentSystem systems
         then []
         else [ currentSystem ]
      else []));

  /**
    ---

    in case someone didn't know that genAttrs is great for dealing with the system variable,
    this is literally just nixpkgs.lib.genAttrs

    ## Arguments

    `systems` (`listOf strings`)

    `f` (`function`)

    ---
  */
  bySystems = lib.genAttrs;

  /**
    ---

    returns a merged set of definitions, with new overriding old.
    updates anything it finds that isn't another set.

    this means it works slightly differently for environment variables
    because each one will be updated individually rather than at a category level.

    Works with both `categoryDefinitions` and individual `packageDefinitions`

    ## Arguments

    `oldCats` (`functionTo` `AttrSet`)
    : accepts `categoryDefinitions` or a single `packageDefinition`

    `newCats` (`functionTo` `AttrSet`)
    : accepts `categoryDefinitions` or a single `packageDefinition`

    ---
  */
  mergeCatDefs = oldCats: newCats:
    (packageDef: lib.recUpdateHandleInlineORdrv (oldCats packageDef) (newCats packageDef));

  /**
    ---

    Same as `mergeCatDefs` but if it encounters a list (usually representing a category)
    it will merge them together rather than replacing the old one with the new one.

    ## Arguments

    `oldCats` (`functionTo` `AttrSet`)
    : accepts `categoryDefinitions` or a single `packageDefinition`

    `newCats` (`functionTo` `AttrSet`)
    : accepts `categoryDefinitions` or a single `packageDefinition`

    ---
  */
  deepmergeCats = oldCats: newCats:
    (packageDef: lib.recursiveUpdateWithMerge (oldCats packageDef) (newCats packageDef));

  /**
    ---

    recursiveUpdate each overlay output to avoid issues where
    two overlays output a set of the same name when importing from other nixCats.
    Merges everything into 1 overlay

    If you have 2 overlays both outputting a set like pkgs.neovimPlugins,
    The second will replace the first.

    This will merge the results instead.

    Returns a SINGLE overlay

    ## Arguments

    `oldOverlist` (`listOf` `overlays`)

    `newOverlist` (`listOf` `overlays`)

    ---
  */
  mergeOverlayLists = oldOverlist: newOverlist: self: super: let
    oldOversMapped = map (value: value self super) oldOverlist;
    newOversMapped = map (value: value self super) newOverlist;
    combinedOversCalled = oldOversMapped ++ newOversMapped;
    mergedOvers = foldl' lib.recursiveUpdateUntilDRV { } combinedOversCalled;
  in
  mergedOvers;

  /**
    ---

    Simple helper function for `mergeOverlayLists`

    If you know the prior `dependencyOverlays` is a list, you dont need this.

    If `dependencyOverlays` is an attrset, system string is required.
    If `dependencyOverlays` is a list, system string is ignored.
    if invalid type or system, returns an empty list

    If you passed in dependencyOverlays as a list to your builder function,
    it will remain a list.

    ## Arguments

    `system` (`string` or `null`)
    : Technically optional if you know `dependencyOverlays` is a list
    : But the whole function isnt required at that point so, this is effectively required

    `dependencyOverlays` (`AttrsOfSystemsOf` `listOf` `overlays` | `listOf` `overlays`)

    ## Example

    ```nix
    dependencyOverlays = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all (system: [
      (utils.mergeOverlayLists # <-- merging 2 lists requires both to be a list
        # safeOversList checks if dependencyOverlays is a list or a set
        (utils.safeOversList { inherit system; inherit (prev) dependencyOverlays; })
        [ # <- and then we add our new list
          (utils.standardPluginOverlay inputs)
          # any other flake overlays here.
        ]
      )
    ]);
    ```

    ---
  */
  safeOversList = { dependencyOverlays, system ? null }:
    if isAttrs dependencyOverlays && system == null then
      throw "dependencyOverlays is a set, but no system was provided"
    else if isAttrs dependencyOverlays && dependencyOverlays ? system then
      dependencyOverlays.${system}
    else if isList dependencyOverlays then
      dependencyOverlays
    else [];

  /**
    ---

    makes a default package and then one for each name in `packageDefinitions`

    for constructing flake outputs.

    ## Arguments
    
    `finalBuilder` (`function`)
    : this is `baseBuilder` with all arguments except `name` applied.

    `packageDefinitions` (`AttrSet`)
    : the set of `packageDefinitions` passed to the builder, passed in again.

    `defaultName` (`string`)
    : the name of the package to be output as default in the resulting set of packages.

    ---
  */
  mkPackages = finalBuilder: packageDefinitions: defaultName:
    { default = finalBuilder defaultName; }
    // mkExtraPackages finalBuilder packageDefinitions;

  /**
    ---

    `mkPackages` but without adding a default package, or the final `defaultName` argument

    ## Arguments
    
    `finalBuilder` (`function`)
    : this is `baseBuilder` with all arguments except `name` applied.

    `packageDefinitions` (`AttrSet`)
    : the set of `packageDefinitions` passed to the builder, passed in again.

    ---
  */
  mkExtraPackages = finalBuilder: packageDefinitions:
  (mapAttrs (name: _: finalBuilder name) packageDefinitions);

  /**
    ---

    like mkPackages but easier.

    Pass it a package and it will make that the default, and build all the packages
    in the packageDefinitions that package was built with.

    ## Arguments

    `package` (`NixCats nvim derivation`)

    ---
  */
  mkAllWithDefault = package:
  { default = package; } // (mkAllPackages package);

  /**
    ---

    like `mkExtraPackages` but easier.

    Pass it a package and it will build all the packages
    in the `packageDefinitions` that package was built with.

    ## Arguments

    `package` (`NixCats nvim derivation`)

    ---
  */
  mkAllPackages = package: let
    allnames = attrNames package.passthru.packageDefinitions;
  in
  listToAttrs (map (name:
    lib.nameValuePair name (package.override { inherit name; })
  ) allnames);

  /**
    ---

    makes a set of overlays from your definitions for exporting from a flake.

    defaultName is the package name for the default overlay

    ## Arguments

    `luaPath` (`function` or `stringWithContext`)

    `pkgsParams` (`AttrSet`)
    : exactly the same as the `pkgsParams` in `baseBuilder`
    : except without `system`

    `categoryDefinitions` (`FunctionTo` `AttrSet`)
    : exactly the same as `categoryDefinitions` in `baseBuilder`

    `packageDefinitions` (`AttrSet` `functionTo` `AttrSet`)
    : exactly the same as `packageDefinitions` in `baseBuilder`

    `defaultName` (`string`)

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
    ---

    makes a set of overlays from your definitions for exporting from a flake.

    Differs from `makeOverlays` in that the default overlay is a set of all the packages

    default overlay yeilds `pkgs.${defaultName}.${packageName}` with all the packages

    ## Arguments

    `luaPath` (`function` or `stringWithContext`)

    `pkgsParams` (`AttrSet`)
    : exactly the same as the `pkgsParams` in `baseBuilder`
    : except without `system`

    `categoryDefinitions` (`FunctionTo` `AttrSet`)
    : exactly the same as `categoryDefinitions` in `baseBuilder`

    `packageDefinitions` (`AttrSet` `functionTo` `AttrSet`)
    : exactly the same as `packageDefinitions` in `baseBuilder`

    `defaultName` (`string`)

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
    ---

    makes a set of overlays from your definitions for exporting from a flake.

    overlay yeilds `pkgs.${importName}.${packageName}`

    contains all the packages named in `namesIncList` (the last argument)

    ## Arguments

    `luaPath` (`function` or `stringWithContext`)

    `pkgsParams` (`AttrSet`)
    : exactly the same as the `pkgsParams` in `baseBuilder`
    : except without `system`

    `categoryDefinitions` (`FunctionTo` `AttrSet`)
    : exactly the same as `categoryDefinitions` in `baseBuilder`

    `packageDefinitions` (`AttrSet` `functionTo` `AttrSet`)
    : exactly the same as `packageDefinitions` in `baseBuilder`

    `importName` (`string`)
    : when applied, overlay yeilds `pkgs.${importName}.${packageName}`

    `namesIncList` (`listOf` `string`)
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
    ---

    `makeMultiOverlay` except it takes only 2 arguments.

    ## Arguments

    `package` (`NixCats nvim derivation`)
    : will include all packages in the `packageDefinitions` the package was built with

    `importName` (`string`)
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
        lib.nameValuePair name (package.override { inherit name; inherit (prev) system; })
      ) allnames);
  });

  /**
    ---

    makes a single overlay with all the packages
    in `packageDefinitions` from the package as `pkgs.${packageName}`

    ## Arguments

    `package` (`NixCats nvim derivation`)
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
    lib.nameValuePair name (package.override { inherit name; inherit (prev) system; })
  ) allnames));

  /**
    ---

    makes a separate overlay for each of the packages
    in `packageDefinitions` from the package as `pkgs.${packageName}`

    ## Arguments

    `package` (`NixCats nvim derivation`)
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
    allnames = attrNames package.passthru.packageDefinitions;
    mapfunc = map (name:
      lib.nameValuePair name (final: prev: {
        ${name} = package.override { inherit (prev) system; };
      }));
  in
  listToAttrs (mapfunc allnames);

}
