This directory contains the entire nixCats builder.

It gets exported by the utils set in [utils/default.nix](../utils/default.nix)

These files drive the category and message passing scheme.

[./default.nix](./default.nix), which depends on [./ncTools.nix](./ncTools.nix) and [./nixCats.lua](./nixCats.lua) and [./nixCatsMeta.lua](./nixCatsMeta.lua) and [./builder_error.nix](./builder_error.nix)

It also imports the help files at [nixCatsHelp](../nixCatsHelp) so that all versions of nixCats have help.
