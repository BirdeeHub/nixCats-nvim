The utils set in default.nix is the interface through which the entire nixCats library is accessed.

As such:

This directory is in charge of exporting the [builder](../builder) and the [templates](../templates) as well as any associated utilities for:

[Importing non-nix plugins without build steps from flake inputs](./autoPluginOverlay.nix)

exporting [home manager modules](./homeManagerModule.nix) and [nixos modules](./nixosModule.nix) based on a [flake](../templates/fresh) or [nixExpressionFlakeOutputs](../templates/nixExpressionFlakeOutputs) based setup

[as well as anything else you should need for manipulating overlays from other flakes, managing the system variable, making overlays, making packages, and making other outputs from the builder,](./default.nix)
