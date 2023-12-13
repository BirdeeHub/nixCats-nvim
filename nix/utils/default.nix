# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
rec {

  # These are to be exported in flake outputs
  utils = {
    # makes a default package and then one for each name in packageDefinitions
    mkPackages = finalBuilder: packageDefinitions: defaultName:
      { default = finalBuilder defaultName; }
      // (builtins.mapAttrs (name: _: finalBuilder name) packageDefinitions);

    # makes an overlay you can add to allow importing as pkgs.packageName
    # and also a default overlay similarly to above but for overlays.
    mkOverlays = finalBuilder: packageDefinitions: defaultName:
      (utils.mkDefaultOverlay finalBuilder defaultName)
      // (utils.mkExtraOverlays finalBuilder packageDefinitions);

    # I may as well make these separate functions.
    mkDefaultOverlay = finalBuilder: defaultName:
      { default = (self: super: { ${defaultName} = finalBuilder defaultName; }); };

    mkExtraOverlays = finalBuilder: packageDefinitions:
      builtins.mapAttrs (name: _: (self: super: { ${name} = finalBuilder name; })) packageDefinitions;

    # maybe you want multiple nvim packages in the same system and want
    # to add them like pkgs.MyNeovims.packageName when you install them?
    # both to keep it organized and also to not have to worry about naming conflicts with programs?
    mkMultiOverlay = finalBuilder: packageDefinitions: importName: namesIncList:
      (self: super: {
        ${importName} = builtins.listToAttrs (
          builtins.map
            (name:
              {
                inherit name;
                value = finalBuilder name;
              }
            ) namesIncList
          );
        }
      );

    # allows for inputs named plugins-something to be turned into plugins automatically
    standardPluginOverlay = import ./standardPluginOverlay.nix;

    # returns a merged set of definitions, with new overriding old.
    # updates anything it finds that isn't another set.
    # this means it works slightly differently for environment variables
    # because each one will be updated individually rather than at a category level.
    mergeCatDefs = oldCats: newCats:
      (packageDef: lib.recursiveUpdateCatDefs (oldCats packageDef) (newCats packageDef));

    # recursiveUpdate each overlay output to avoid issues where
    # two overlays output a set of the same name when importing from other nixCats.
    # Merges everything into 1 overlay
    mergeOverlayLists = oldOverlist: newOverlist: self: super: let
      oldOversMapped = builtins.map (value: value self super) oldOverlist;
      newOversMapped = builtins.map (value: value self super) newOverlist;
      combinedOversCalled = oldOversMapped ++ newOversMapped;
      mergedOvers = super.lib.foldr super.lib.recursiveUpdate { } combinedOversCalled;
    in
    mergedOvers;


    mkNixosModules = {
      nixpkgs
      , inputs
      , otherOverlays
      , baseBuilder
      , luaPath ? ""
      , keepLuaBuilder ? null
      , pkgs
      , categoryDefinitions
      , packageDefinitions
      , defaultPackageName }@exports: (import ./nixosModule.nix exports utils);

    mkHomeModules = {
      nixpkgs
      , inputs
      , otherOverlays
      , baseBuilder
      , luaPath ? ""
      , keepLuaBuilder ? null
      , pkgs
      , categoryDefinitions
      , packageDefinitions
      , defaultPackageName }@exports: (import ./homeManagerModule.nix exports utils);

    templates = {
      fresh = {
        path = ../templates/fresh;
        description = "starting point template for making your neovim flake";
      };
      nixosModule = {
        path = ../templates/nixosModule;
        description = "nixOS module configuration template";
      };
      homeModule = {
        path = ../templates/homeManager;
        description = "Home Manager module configuration template";
      };
      mergeFlakeWithExisting = {
        path = ../templates/touchUpExisting;
        description = "A template showing how to merge in parts of other nixCats repos";
      };

      default = utils.templates.fresh;
    };

  };

# The following are part of the builder and do not need to be separately exported.

# NIX CATS SECTION:

  # 2 recursive functions that rely on each other to
  # convert nix attrsets and lists to Lua tables and lists of strings, 
  # while literally translating booleans and null
  luaTablePrinter = with builtins; attrSet: let
    luatableformatter = attrSet: let
      nameandstringmap = mapAttrs (n: value: let
          name = ''["${n}"]'';
        in
        if value == true then "${name} = true"
        else if value == false then "${name} = false"
        else if value == null then "${name} = nil"
        else if isList value then "${name} = ${luaListPrinter value}"
        else if isAttrs value then "${name} = ${luaTablePrinter value}"
        else "${name} = [[${toString value}]]"
      ) attrSet;
      resultList = attrValues nameandstringmap;
      resultString = concatStringsSep ", " resultList;
    in
    resultString;
    catset = luatableformatter attrSet;
    LuaTable = "{ " + catset + " }";
  in
  LuaTable;

  luaListPrinter = with builtins; theList: let
    lualistformatter = theList: let
      stringlist = map (value:
        if value == true then "true"
        else if value == false then "false"
        else if value == null then "nil"
        else if isList value then "${luaListPrinter value}"
        else if isAttrs value then "${luaTablePrinter value}"
        else "[[${toString value}]]"
      ) theList;
      resultString = concatStringsSep ", " stringlist;
    in
    resultString;
    catlist = lualistformatter theList;
    LuaList = "{ " + catlist + " }";
  in
  LuaList;


# NEOVIM BUILDER SECTION:

  # returns a flattened list with only those lists 
  # whose name was associated with a true value within the categories set
  filterAndFlatten = categories: categoryDefs:
    flattenToList (RecFilterCats categories categoryDefs);

  filterAndFlattenMapInnerAttrs = categories: twoArgFunc: categoryDefs:
    flattenAttrMapLeaves twoArgFunc (RecFilterCats categories categoryDefs);

  filterAndFlattenMapInner = categories: oneArgFunc: SetOfCategoryLists:
    builtins.map oneArgFunc (filterAndFlatten categories SetOfCategoryLists);

  RecFilterForTrue = with builtins; categories: let 
    filterIt = attr: (lib.filterAttrs (name: value:
        if isBool value
        then value
        else if isAttrs value && !lib.isDerivation value
        then true
        else false
      ) attr);
    mapper = cats: mapAttrs (name: value:
        if isBool value then value else mapper (filterIt value)
      ) (filterIt cats);
  in
  mapper categories;

  RecFilterCats = with builtins; categories: categoryDefs: let
    mapper = subCats: defAttrs: mapAttrs 
        (name: value: let
          newDefAttr = getAttr name defAttrs;
        in
        if !(isAttrs value && isAttrs newDefAttr) || lib.isDerivation newDefAttr
        then newDefAttr
        else mapper value newDefAttr)
      (intersectAttrs defAttrs subCats);
  in
  mapper (RecFilterForTrue categories) categoryDefs;

  flattenToList = with builtins; attrset: concatMap
    (v:
      if isAttrs v && !lib.isDerivation v then flattenToList v else
      (if isList v then v else [v])
    ) (attrValues attrset);

  flattenAttrMapLeaves = with builtins; twoArgFunc: attrset: let
    mapAttrValues = attr: attrValues (mapAttrs (name: value:
        if (isList value || isAttrs value)
        then value
        else (twoArgFunc name value)
      ) attr);
    flatten = attr: concatMap (v:
        if isAttrs v && !lib.isDerivation v then flatten v else
        (if isList v then v else [v])
      ) (mapAttrValues attr);
  in
  flatten attrset;

  # https://github.com/NixOS/nixpkgs/blob/nixos-23.05/lib/attrsets.nix
  lib = with builtins; {
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

    recursiveUpdateCatDefs = lhs: rhs:
      lib.recursiveUpdateUntil (path: lhs: rhs:
            # I added this check for derivation because a category can be just a derivation.
            # otherwise it would squish our single derivation category rather than update.
          (!(isAttrs lhs && isAttrs rhs) && !(lib.isDerivation lhs && lib.isDerivation rhs))
        ) lhs rhs;

    filterAttrs = pred: set:
      listToAttrs (concatMap 
        (name: let value = set.${name}; in
          if pred name value then
          [({ inherit name value; })]
          else []
        ) (attrNames set));

  };
}

