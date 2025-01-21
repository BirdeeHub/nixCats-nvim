# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
# This overlay grabs all the inputs named in the format
# `plugins-<pluginName>`
# Once we add this overlay to our nixpkgs, we are able to
# use `pkgs.neovimPlugins`, which is a set of our plugins.
# Source: https://github.com/Quoteme/neovim-flake/blob/34c47498114f43c243047bce680a9df66abfab18/flake.nix#L42C8-L42C8
{
  standardPluginOverlay = inputs:
  (self: super:
  let
    inherit (super.vimUtils) buildVimPlugin;
    plugins = builtins.filter
      (s: (builtins.match "plugins-.*" s) != null)
      (builtins.attrNames inputs);
    plugName = input:
      builtins.substring
        (builtins.stringLength "plugins-")
        (builtins.stringLength input)
        input;
    buildPlug = name: buildVimPlugin rec {
      pname = plugName name;
      src = builtins.getAttr name inputs;
      doCheck = false;
      version = toString (src.lastModified or "master");
    };
  in
  {
    neovimPlugins = builtins.listToAttrs (map
      (plugin: {
        name = plugName plugin;
        value = buildPlug plugin;
      })
      plugins);
  });
  # same as standardPluginOverlay except if you give it `plugins-foo.bar`
  # you can `pkgs.neovimPlugins.foo-bar` and still `packadd foo.bar`
  sanitizedPluginOverlay = inputs:
  (self: super:
  let
    inherit (super.vimUtils) buildVimPlugin;
    plugins = builtins.filter
      (s: (builtins.match "plugins-.*" s) != null)
      (builtins.attrNames inputs);
    plugName = input:
      builtins.substring
        (builtins.stringLength "plugins-")
        (builtins.stringLength input)
        input;
    plugAttrName = input: builtins.replaceStrings [ "." ] [ "-" ] (plugName input);
    buildPlug = name: buildVimPlugin rec {
      pname = plugName name;
      src = builtins.getAttr name inputs;
      doCheck = false;
      version = toString (src.lastModified or "master");
    };
  in
  {
    neovimPlugins = builtins.listToAttrs (map
      (plugin: {
        name = plugAttrName plugin;
        value = buildPlug plugin;
      })
      plugins);
  });
}
