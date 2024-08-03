This directory contains the entire nixCats builder.

It gets exported by the utils set in [nix/utils/default.nix](../utils/default.nix)

These are original and drive the category and message passing scheme.

[./default.nix](./default.nix), which depends on [./ncTools.nix](./ncTools.nix) and [./nixCats.lua](./nixCats.lua) and [./nixCatsMeta.lua](./nixCatsMeta.lua)

default.nix also passes the nixCats plugin along as a function, to add more info later.

It also imports the help files at [nix/nixCatsHelp](../nixCatsHelp) so that all versions of nixCats have help.

These files are modified from nixpkgs to allow multi-installation, and to pass more info to lua:

[./wrapNeovim.nix](./wrapNeovim.nix) which depends on [./wrapenvs.nix](./wrapenvs.nix) and [./wrapper.nix](./wrapper.nix) which depends on [./vim-pack-dir.nix](./vim-pack-dir.nix)
