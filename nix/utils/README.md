This directory is in charge of exporting the [builder](../builder) and the [templates](../templates) as well as any associated utilities for:

[Importing non-nix plugins without build steps from flake inputs](./standardPluginOverlay.nix)

exporting [home manager modules](./homeManagerModule.nix) and [nixos modules](./nixosModule.nix) based on a [flake](../templates/fresh) or [nixExpressionFlakeOutputs](../templates/nixExpressionFlakeOutputs) based setup

[as well as anything else you should need for manipulating overlays from other flakes, managing the system variable, making overlays, making packages, and making other outputs from the builder,](./default.nix)

---

Usage of the things exported in this directory is in the help at [:help nixCats.*](../nixCatsHelp), as well as the rest of this repository.

Yes, everything outside of this directory and the [builder directory](../builder) is either help, example, or templates.

The utils set in [nix/utils/default.nix](./default.nix) is exported from the main flake of this repo, and contains everything you will need to make a nixCats based config of your own.

This means that the entire nix directory does not need to be included in your personal configuration, everything you need is in the utils set, which is exported by this flake.

The 3 main templates mentioned in [:h nixCats.installation_options](../nixCatsHelp/installation.txt) all consist of a single nix file (or 2 for the modules template, one for home manager and one for nixos), and an empty skeleton of an overlays directory should it ever be required.

There is also an optional [luaUtils template](../templates/luaUtils) containing tools to check if nix was used to load your configuration, as well as a wrapper for lazy.nvim and pckr. There is help for this feature at [:h nixCats.luaUtils](../nixCatsHelp/luaUtils.txt)

For other plugin managers, look at the example in the pckr wrapper. I promise you can replicate. lazy.nvim is the only notable one that parts with the normal plugin management scheme.

The [templates](../templates) and the [example config (the top level of the repo minus the nix directory)](../..) and the [:help](../nixCatsHelp) are there to guide you along the way!
