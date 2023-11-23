# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
rec {

# NIX CATS SECTION:

  # 2 recursive functions that rely on each other to
  # convert nix attrsets and lists to Lua tables and lists of strings.
  luaTablePrinter = attrSet: let
    luatableformatter = attrSet: let
      nameandstringmap = builtins.mapAttrs (name: value:
        if value == true then "${name} = true"
        else if value == false then "${name} = false"
        else if value == null then "${name} = nil"
        else if builtins.isList value then "${name} = ${luaListPrinter value}"
        else if builtins.isAttrs value then "${name} = ${luaTablePrinter value}"
        else "${name} = [[${builtins.toString value}]]"
      ) attrSet;
      resultList = builtins.attrValues nameandstringmap;
      resultString = builtins.concatStringsSep ", " resultList;
    in
    resultString;
    catset = luatableformatter attrSet;
    LuaTable = "{ " + catset + " }";
  in
  LuaTable;

  luaListPrinter = theList: let
    lualistformatter = theList: let
      stringlist = builtins.map (value:
        if value == true then "true"
        else if value == false then "false"
        else if value == null then "nil"
        else if builtins.isList value then "${luaListPrinter value}"
        else if builtins.isAttrs value then "${luaTablePrinter value}"
        else "[[${builtins.toString value}]]"
      ) theList;
      resultString = builtins.concatStringsSep ", " stringlist;
    in
    resultString;
    catlist = lualistformatter theList;
    LuaList = "{ " + catlist + " }";
  in
  LuaList;


# NEOVIM BUILDER SECTION:

  # takes an attrset of lists and an attrset of booleans,
  # and returns a flattened list with only those lists 
  # whose name was associated with a true value within the categories set
  filterAndFlattenAttrsOfLists = pkgs: categories: SetOfCategoryLists: let
    inputsToCheck = builtins.intersectAttrs SetOfCategoryLists categories;
    thingsIncluded = builtins.mapAttrs (name: value:
        if value == true then builtins.getAttr name SetOfCategoryLists else []
      ) inputsToCheck;
    listOfLists = builtins.attrValues thingsIncluded;
    flattenedList = builtins.concatLists listOfLists;
    flattenedUniqueList = pkgs.lib.unique flattenedList;
  in
  flattenedUniqueList;

  # takes an attrset of attrsets and an attrset of booleans,
  # and returns a flattened list with only those sets 
  # whose name was associated with a true value within the categories set
  # and each of the items in the inner attrset that were included are mapped to
  # a string based on the function action which takes 2 arguments
  FilterAttrsOfAttrsFlatMapInner = pkgs: categories: twoArgFunc: SetOfCategoryAttrs: let
    inputsToCheck = builtins.intersectAttrs SetOfCategoryAttrs categories;
    thingsIncluded = builtins.mapAttrs (name: value:
        if value == true then builtins.getAttr name SetOfCategoryAttrs else []
      ) inputsToCheck;
    listOfAttrs = builtins.attrValues thingsIncluded;
    listOfListOfStrings = builtins.map (setOfVars: let
        mappedAttrs = builtins.mapAttrs twoArgFunc setOfVars;
        listOfStrings = builtins.attrValues mappedAttrs;
      in
      listOfStrings
    ) listOfAttrs;
    flattenedList = builtins.concatLists listOfListOfStrings;
    flattenedUniqueList = pkgs.lib.unique flattenedList;
  in
  flattenedUniqueList;
  
  #same as above but action can only take 1 argument, and the inner thing is lists
  # as opposed to above where the inner thing is an attribute set.
  # since we already wrote a function for sets of lists, we use that.
  FilterAttrsOfListsFlatMapInner = pkgs: categories: oneArgFunc: SetOfCategoryLists: let
    FandFed = filterAndFlattenAttrsOfLists pkgs categories SetOfCategoryLists;
    mapped = builtins.map oneArgFunc FandFed;
  in
  mapped;

  runtimepathcopier = self: ''
    source $stdenv/setup
    mkdir -p $out
    if [ -e ${self}/filetype.lua ]; then
        cp -r ${self}/filetype.lua $out/
    fi
    if [ -d ${self}/autoload ]; then
        mkdir -p $out/autoload && cp -r ${self}/autoload/* $out/autoload
    fi
    if [ -d ${self}/colors ]; then
        mkdir -p $out/colors && cp -r ${self}/colors/* $out/colors
    fi
    if [ -d ${self}/compiler ]; then
        mkdir -p $out/compiler && cp -r ${self}/compiler/* $out/compiler
    fi
    if [ -d ${self}/doc ]; then
        mkdir -p $out/doc && cp -r ${self}/doc/* $out/doc
    fi
    if [ -d ${self}/ftplugin ]; then
        mkdir -p $out/ftplugin && cp -r ${self}/ftplugin/* $out/ftplugin
    fi
    if [ -d ${self}/indent ]; then
        mkdir -p $out/indent && cp -r ${self}/indent/* $out/indent
    fi
    if [ -d ${self}/keymap ]; then
        mkdir -p $out/keymap && cp -r ${self}/keymap/* $out/keymap
    fi
    if [ -d ${self}/lang ]; then
        mkdir -p $out/lang && cp -r ${self}/lang/* $out/lang
    fi
    if [ -d ${self}/lua ]; then
        mkdir -p $out/lua && cp -r ${self}/lua/* $out/lua
    fi
    if [ -d ${self}/menu.vim ]; then
        mkdir -p $out/menu.vim && cp -r ${self}/menu/*.vim $out/menu
    fi
    if [ -d ${self}/pack ]; then
        mkdir -p $out/pack && cp -r ${self}/pack/* $out/pack
    fi
    if [ -d ${self}/parser ]; then
        mkdir -p $out/parser && cp -r ${self}/parser/* $out/parser
    fi
    if [ -d ${self}/plugin ]; then
        mkdir -p $out/plugin && cp -r ${self}/plugin/* $out/plugin
    fi
    if [ -d ${self}/queries ]; then
        mkdir -p $out/queries && cp -r ${self}/queries/* $out/queries
    fi
    if [ -d ${self}/rplugin ]; then
        mkdir -p $out/rplugin && cp -r ${self}/rplugin/* $out/rplugin
    fi
    if [ -d ${self}/spell ]; then
        mkdir -p $out/spell && cp -r ${self}/spell/* $out/spell
    fi
    if [ -d ${self}/syntax ]; then
        mkdir -p $out/syntax && cp -r ${self}/syntax/* $out/syntax
    fi
    if [ -d ${self}/tutor ]; then
        mkdir -p $out/tutor && cp -r ${self}/tutor/* $out/tutor
    fi
  '';
}
