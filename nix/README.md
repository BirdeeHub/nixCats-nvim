This directory contains the internals of nixCats.

[./builder](./builder) and [./utils](./utils) contain the implementation of the nixCats wrapper.

[./templates](./templates) contains the starter templates, and some examples of various aspects of nix, neovim, or this project.
You can initialize them into a directory with `nix flake init -t github:BirdeeHub/nixCats#<templatename>`

[./nixCatsHelp](./nixCatsHelp) contains the in-editor documentation.

This directory is imported from github by the templates under `inputs.nixCats.utils` and does not need to be present in your personal config.

Everything you may need is exported by the utils set within [./utils/default.nix](./utils/default.nix)

Everything outside of this directory is the example config of nixCats, runnable with `nix run github:BirdeeHub/nixCats`.

You should look through it to see examples of things you may have questions about.
