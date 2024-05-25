# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
with builtins; rec {
  # These are to be exported in flake outputs
  utils = {
    # The big function that does everything
    baseBuilder = import ../builder;

    templates = import ../templates;

    # allows for inputs named plugins-something to be turned into plugins automatically
    standardPluginOverlay = import ./standardPluginOverlay.nix;

    # returns a merged set of definitions, with new overriding old.
    # updates anything it finds that isn't another set.
    # this means it works slightly differently for environment variables
    # because each one will be updated individually rather than at a category level.
    mergeCatDefs = oldCats: newCats:
      (packageDef: lib.recursiveUpdateUntilDRV (oldCats packageDef) (newCats packageDef));

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

    # makes a default package and then one for each name in packageDefinitions
    mkPackages = finalBuilder: packageDefinitions: defaultName:
      { default = finalBuilder defaultName; }
      // utils.mkExtraPackages finalBuilder packageDefinitions;

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
        makeOverlay = name: final: prev: {
          ${name} = utils.baseBuilder luaPath (pkgsParams // { inherit (final) system; }) categoryDefFunction packageDefinitions name;
        };
        overlays = (mapAttrs (name: _: makeOverlay name) packageDefinitions) // { default = (makeOverlay defaultName); };
      in overlays;

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
      (self: super: {
        ${importName} = listToAttrs (
          map
            (name:
              {
                inherit name;
                value =  utils.baseBuilder luaPath (pkgsParams // { inherit (final) system; }) categoryDefFunction packageDefinitions name;
              }
            ) namesIncList
          );
        }
      );

    mkNixosModules = {
      dependencyOverlays
      , luaPath ? ""
      , keepLuaBuilder ? null
      , categoryDefinitions
      , packageDefinitions
      , defaultPackageName
      , nixpkgs
      , ... }:
      (import ./nixosModule.nix {
        oldDependencyOverlays = dependencyOverlays;
        inherit nixpkgs luaPath keepLuaBuilder categoryDefinitions
          packageDefinitions defaultPackageName utils;
      });

    mkHomeModules = {
      dependencyOverlays
      , luaPath ? ""
      , keepLuaBuilder ? null
      , categoryDefinitions
      , packageDefinitions
      , defaultPackageName
      , nixpkgs
      , ... }:
      (import ./homeManagerModule.nix {
        oldDependencyOverlays = dependencyOverlays;
        inherit nixpkgs luaPath keepLuaBuilder categoryDefinitions
          packageDefinitions defaultPackageName utils;
      });

    # These were deprecated due to needing to be wrapped with ${system} and thus failing flake check
    mkOverlays = finalBuilder: packageDefinitions: defaultName:
      let
        warn = trace "WARNING: utils.mkOverlays is deprecated. Use utils.makeOverlays instead.";
      in (warn (
          (utils.mkDefaultOverlay finalBuilder defaultName) 
          //
          (utils.mkExtraOverlays finalBuilder packageDefinitions)
        )
      );

    mkDefaultOverlay = finalBuilder: defaultName:
      let
        warn = trace "WARNING: utils.mkDefaultOverlay is deprecated. It may be removed in the future.";
      in warn { default = (self: super: { ${defaultName} = finalBuilder defaultName; }); };

    mkExtraOverlays = finalBuilder: packageDefinitions:
      let
        warn = trace "WARNING: utils.mkExtraOverlays is deprecated. It may be removed in the future.";
      in warn (mapAttrs (name: (self: super: { ${name} = finalBuilder name; })) packageDefinitions);

    mkMultiOverlay = finalBuilder: importName: namesIncList:
      let
        warn = trace "WARNING: utils.mkMultiOverlay is deprecated. Use utils.makeMultiOverlay instead.";
      in (warn 
          (self: super: {
            ${importName} = listToAttrs (
              map
                (name:
                  {
                    inherit name;
                    value = finalBuilder name;
                  }
                ) namesIncList
              );
            }
          )
        );
  };

  # https://github.com/NixOS/nixpkgs/blob/nixos-23.05/lib/attrsets.nix
  lib = {
    isDerivation = value: value.type or null == "derivation";

    recursiveUpdateUntil = pred: lhs: rhs:
      let f = attrPath:
        zipAttrsWith (n: values:
          let here = attrPath ++ [n]; in
          if length values == 1
          || pred here (elemAt values 1) (head values) then
            head values
          else
            f here values
        );
      in f [] [rhs lhs];

    recursiveUpdateUntilDRV = lhs: rhs:
      lib.recursiveUpdateUntil (path: lhs: rhs:
            # I added this check for derivation because a category can be just a derivation.
            # otherwise it would squish our single derivation category rather than update.
          (!((isAttrs lhs && !lib.isDerivation lhs) && (isAttrs rhs && !lib.isDerivation rhs)))
        ) lhs rhs;
  };
}

