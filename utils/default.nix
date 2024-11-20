# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
# NOTE: This file exports the entire public interface for nixCats
with builtins; let lib = import ./lib.nix; in rec {
  /**
    The main builder function of nixCats.

    # Arguments

    - [luaPath]: store path to your ~/.config/nvim replacement within your nix config.

    - [pkgsParams]: set of items for building the pkgs that builds your neovim.
      accepted attributes are:
      - nixpkgs, # <-- required. allows path, input, or channel
      - system, # <-- required unless nixpkgs is a resolved channel
      - dependencyOverlays ? null,

        `listOf overlays` or `attrsOf (listOf overlays)` or `null`

      - extra_pkg_config ? {},

        the attrset passed to:
        `import nixpkgs { config = extra_pkg_config; inherit system; }`

      - nixCats_passthru ? {},

        attrset of extra stuff for finalPackage.passthru

    - [categoryDefinitions]:

      type: function with args `{ pkgs, settings, categories, name, extra, mkNvimPlugin, ... }:`

      returns: set of sets of categories of dependencies

      see :h nixCats.flake.outputs.categories

    - [packageDefinitions]: 
      set of functions that each represent the settings and included categories for that package.

      ```nix
      {
        nvim = { pkgs, mkNvimPlugin, ... }: { settings = {}; categories = {}; extra = {}; };
      }
      ```

      see :h nixCats.flake.outputs.packageDefinitions

      see :h nixCats.flake.outputs.settings

    - [name]: 
      name of the package to build from `packageDefinitions`

    # Note:

    When using override, all values shown above will
    be top level attributes of prev, none will be nested.

    i.e. finalPackage.override (prev: { inherit (prev) dependencyOverlays; })
    
    NOT prev.pkgsParams.dependencyOverlays or something like that
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

  /** a set of templates to get you started. See :h nixCats.templates */
  templates = import ../templates;

  # allows for inputs named plugins-something to be turned into plugins automatically
  standardPluginOverlay = (import ./autoPluginOverlay.nix).standardPluginOverlay;

  # same as standardPluginOverlay except if you give it `plugins-foo.bar`
  # you can `pkgs.neovimPlugins.foo-bar` and still `packadd foo.bar`
  sanitizedPluginOverlay = (import ./autoPluginOverlay.nix).sanitizedPluginOverlay;

  # returns a merged set of definitions, with new overriding old.
  # updates anything it finds that isn't another set.
  # this means it works slightly differently for environment variables
  # because each one will be updated individually rather than at a category level.
  mergeCatDefs = oldCats: newCats:
    (packageDef: lib.recUpdateHandleInlineORdrv (oldCats packageDef) (newCats packageDef));

  # allows category list definitions to be merged
  deepmergeCats = oldCats: newCats:
    (packageDef: lib.recursiveUpdateWithMerge (oldCats packageDef) (newCats packageDef));

  # recursiveUpdate each overlay output to avoid issues where
  # two overlays output a set of the same name when importing from other nixCats.
  # Merges everything into 1 overlay
  mergeOverlayLists = oldOverlist: newOverlist: self: super: let
    oldOversMapped = map (value: value self super) oldOverlist;
    newOversMapped = map (value: value self super) newOverlist;
    combinedOversCalled = oldOversMapped ++ newOversMapped;
    mergedOvers = foldl' lib.recursiveUpdateUntilDRV { } combinedOversCalled;
  in
  mergedOvers;

  # if your dependencyOverlays is a list rather than a system-wrapped set,
  # to deal with when other people output an overlay wrapped in a system variable
  # you may call the following function on it.
  fixSystemizedOverlay = overlaysSet: outfunc:
    (final: prev: if !(overlaysSet ? prev.system) then {}
      else (outfunc prev.system) final prev);

  # Simple helper function for mergeOverlayLists
  # If dependencyOverlays is an attrset, system string is required.
  # If dependencyOverlays is a list, system string is ignored
  # if invalid type or system, returns an empty list
  safeOversList = { dependencyOverlays, system ? null }:
    if isAttrs dependencyOverlays && system == null then
      throw "dependencyOverlays is a set, but no system was provided"
    else if isAttrs dependencyOverlays && dependencyOverlays ? system then
      dependencyOverlays.${system}
    else if isList dependencyOverlays then
      dependencyOverlays
    else [];

  mkNixosModules = {
    dependencyOverlays ? null
    , luaPath ? ""
    , keepLuaBuilder ? null
    , categoryDefinitions ? (_:{})
    , packageDefinitions ? {}
    , defaultPackageName
    , nixpkgs ? null
    , extra_pkg_config ? {}
    , ... }:
    (import ./mkModules.nix {
      isHomeManager = false;
      oldDependencyOverlays = dependencyOverlays;
      nclib = lib;
      utils = import ./.;
      inherit nixpkgs luaPath keepLuaBuilder categoryDefinitions
        packageDefinitions defaultPackageName extra_pkg_config;
    });

  mkHomeModules = {
    dependencyOverlays ? null
    , luaPath ? ""
    , keepLuaBuilder ? null
    , categoryDefinitions ? (_:{})
    , packageDefinitions ? {}
    , defaultPackageName
    , nixpkgs ? null
    , extra_pkg_config ? {}
    , ... }:
    (import ./mkModules.nix {
      isHomeManager = true;
      oldDependencyOverlays = dependencyOverlays;
      nclib = lib;
      utils = import ./.;
      inherit nixpkgs luaPath keepLuaBuilder categoryDefinitions
        packageDefinitions defaultPackageName extra_pkg_config;
    });

  # you can use this to make values in the tables generated
  # for the nixCats plugin using lua literals.
  # i.e. cache_location = utils.n2l.types.inline-safe.mk "vim.fn.stdpath('cache')",
  inherit (lib) n2l;

  # flake-utils' main function, because its all I used
  # Builds a map from <attr>=value to <attr>.<system>=value for each system
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

  # in case someoneone wants flake-utils but for only 1 output,
  # and didnt know genAttrs is great as a bySystems
  bySystems = lib.genAttrs;

  # makes a default package and then one for each name in packageDefinitions
  mkPackages = finalBuilder: packageDefinitions: defaultName:
    { default = finalBuilder defaultName; }
    // mkExtraPackages finalBuilder packageDefinitions;

  mkExtraPackages = finalBuilder: packageDefinitions:
  (mapAttrs (name: _: finalBuilder name) packageDefinitions);

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

  easyMultiOverlayNamespaced = package: importName: let
    allnames = attrNames package.passthru.packageDefinitions;
  in
  (final: prev: {
    ${importName} = listToAttrs (map (name:
        lib.nameValuePair name (package.override { inherit name; inherit (prev) system; })
      ) allnames);
  });

  mkAllPackages = package: let
    allnames = attrNames package.passthru.packageDefinitions;
  in
  listToAttrs (map (name:
    lib.nameValuePair name (package.override { inherit name; })
  ) allnames);

  mkAllWithDefault = package:
  { default = package; } // (mkAllPackages package);

  easyMultiOverlay = package: let
    allnames = attrNames package.passthru.packageDefinitions;
  in
  (final: prev: listToAttrs (map (name:
    lib.nameValuePair name (package.override { inherit name; inherit (prev) system; })
  ) allnames));

  easyNamedOvers = package: let
    allnames = attrNames package.passthru.packageDefinitions;
    mapfunc = map (name:
      lib.nameValuePair name (final: prev: {
        ${name} = package.override { inherit (prev) system; };
      }));
  in
  listToAttrs (mapfunc allnames);

  # maybe you want multiple nvim packages in the same system and want
  # to add them like pkgs.MyNeovims.packageName when you install them?
  # both to keep it organized and also to not have to worry about naming conflicts with programs?
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

  # DEPRECATED
  mkLuaInline = trace "utils.mkLuaInline renamed to utils.n2l.types.inline-safe.mk, due to be removed before 2025" lib.n2l.types.inline-safe.mk;
  inherit (lib) catsWithDefault;

}
