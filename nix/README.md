This directory contains the internals of nixCats.

[./builder](./builder) and [./utils](./utils) contain the implementation of the nixCats wrapper.

[./templates](./templates) contains the starter templates, and some examples of various aspects of nix, neovim, or this project.
You can initialize them into a directory with `nix flake init -t github:BirdeeHub/nixCats#<templatename>`

[./nixCatsHelp](./nixCatsHelp) contains the in-editor documentation.

This directory is imported from github by the templates under `inputs.nixCats.utils` and does not need to be present in your personal config.

Everything you may need is exported by the utils set within [./utils/default.nix](./utils/default.nix)

Everything outside of this directory is the example config of nixCats, runnable with `nix run github:BirdeeHub/nixCats`.

You should look through it to see examples of things you may have questions about.

---

Usage of the things exported in this directory is in the templates listed in [:h nixCats.installation_options](../nixCatsHelp/installation.txt), the help at [:help nixCats.*](../nixCatsHelp), as well as the rest of this repository.

The 3 main templates mentioned in [:h nixCats.installation_options](../nixCatsHelp/installation.txt) all consist of a single nix file (or 2 for the modules template, one for home manager and one for nixos), and an empty skeleton of an overlays directory should it ever be required.

There is also an optional [luaUtils template](../templates/luaUtils) containing tools to check if nix was used to load your configuration, as well as a wrapper for lazy.nvim and pckr. There is help for this feature at [:h nixCats.luaUtils](../nixCatsHelp/luaUtils.txt)

For other plugin managers, look at the example in the pckr wrapper. I promise you can replicate. lazy.nvim is the only notable one that parts with the normal plugin management scheme.

The [templates](../templates) and the [example config (the top level of the repo minus the nix directory)](../..) and the [:help](../nixCatsHelp) are there to guide you along the way!
