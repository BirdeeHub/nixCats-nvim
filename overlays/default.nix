inputs: let 
  overlaySet = {

    # this is how you would add another overlay file
    # for if your customBuildsOverlay gets too long
    customBuilds = import ./customBuildsOverlay.nix inputs;

    # This overlay grabs all the inputs named in the format
    # `plugins-<pluginName>`
    # Once we add this overlay to our nixpkgs, we are able to
    # use `pkgs.neovimPlugins`, which is a set of our plugins.
    # Source: https://github.com/Quoteme/neovim-flake/blob/34c47498114f43c243047bce680a9df66abfab18/flake.nix#L42C8-L42C8
    standardPluginOverlay = self: super:
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
      buildPlug = name: buildVimPlugin {
        pname = plugName name;
        version = "master";
        src = builtins.getAttr name inputs;
      };
    in
    {
      neovimPlugins = builtins.listToAttrs (map
        (plugin: {
          name = plugName plugin;
          value = buildPlug plugin;
        })
        plugins);
    };
  };
in
builtins.attrValues overlaySet
