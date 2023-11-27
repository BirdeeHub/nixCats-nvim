inputs: let 
  overlaySet = {

    # this is how you would add another overlay file
    # for if your customBuildsOverlay gets too long
    customBuilds = import ./customBuildsOverlay.nix inputs;

    # This overlay grabs all the inputs named in the format
    # `plugins-<pluginName>`
    # Once we add this overlay to our nixpkgs, we are able to
    # use `pkgs.neovimPlugins`, which is a set of our plugins.
    standardPluginOverlay = import ./standardPluginOverlay.nix inputs;
  };
in
builtins.attrValues overlaySet
