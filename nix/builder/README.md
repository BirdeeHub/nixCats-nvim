This directory contains the entire nixCats builder.

It gets exported by the utils set in [nix/utils/default.nix](../utils/default.nix)

These are original and drive the category and message passing scheme:

[./default.nix](./default.nix)
[./ncTools.nix](./ncTools.nix)
[./nixCats.lua](./nixCats.lua)

These are modified from nixpkgs to allow multi-installation, and to pass more info to lua:

[./wrapNeovim.nix](./wrapNeovim.nix)
[./wrapper.nix](./wrapper.nix)
[./vim-pack-dir.nix](./vim-pack-dir.nix)

It also imports the help files at [nix/nixCatsHelp](../nixCatsHelp) so that all versions of nixCats have help.
