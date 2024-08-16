This directory contains the internals of nixCats.

If you do not wish to use packages or modules based on my configuration, and would rather
have your own config and have modules based on your own configuration, you dont need the main flake.

This directory is imported from github by the templates under `inputs.nixCats.utils` and does not need to be present in your personal config.

Everything you need is in the utils set.

If you used the default, or nixExpressionFlakeOutputs template,
your template will instruct you to use this flake as follows:

```nix
inputs.nixCats.url = "github:BirdeeHub/nixCats-nvim?dir=nix";
# or
inputs.nixCats.url = "github:BirdeeHub/nixCats-nvim/<ref_or_rev>?dir=nix";

# note, this makes the following no longer relevant:
# inputs.nixCats.inputs.nixpkgs.follows = "nixpkgs";
```

---

[./builder](./builder) and [./utils](./utils) contain the implementation of the nixCats wrapper.

[./templates](./templates) contains the starter templates, and some examples of various aspects of nix, neovim, or this project.
You can initialize them into a directory with `nix flake init -t github:BirdeeHub/nixCats#<templatename>`

[./nixCatsHelp](https://nixcats.org) contains the in-editor documentation.

Everything you may need is exported by the utils set within [./utils/default.nix](./utils/default.nix) and documented at [:h nixCats.flake.outputs.exports](https://nixcats.org/nixCats_format.html)

Everything outside of this directory is the example config of nixCats, runnable with `nix run github:BirdeeHub/nixCats`.

You should look through it to see examples of things you may have questions about.

---

Usage of the things exported in this directory is in the templates listed in [:h nixCats.installation_options](https://nixcats.org/nixCats_installation.html), the help at [:help nixCats.*](https://nixcats.org), as well as the rest of this repository.

The starter templates mentioned in [:h nixCats.installation_options](https://nixcats.org/nixCats_installation.html) all consist of a single nix file (or 2 for the modules template, one for home manager and one for nixos), and an empty skeleton of an overlays directory should it ever be required.

There is also an optional [luaUtils template](../templates/luaUtils) containing tools to check if nix was used to load your configuration, as well as a wrapper for lazy.nvim and pckr. There is help for this feature at [:h nixCats.luaUtils](https://nixcats.org/nixCats_luaUtils.html)

For other plugin managers, look at the example in the pckr wrapper. I promise you can replicate. lazy.nvim is the only notable one that parts with the normal plugin management scheme.

The [templates](../templates) and the [example config (the top level of the repo minus the nix directory)](./..) and the [:help](https://nixcats.org) are there to guide you along the way!
