This directory contains the entire nixCats builder.

It gets exported by the utils set in [utils/default.nix](../utils/default.nix)

These files drive the category and message passing scheme.

[./default.nix](./default.nix), which depends on
- [./ncTools.nix](./ncTools.nix)
- [./nixCats.lua](./nixCats.lua)
- [./nixCatsMeta.lua](./nixCatsMeta.lua)
- [./normalizePlugins.nix](./normalizePlugins.nix)
- [./builder_error.nix](./builder_error.nix)
- [nixCatsHelp](../nixCatsHelp)

Then default.nix passes on the sorted arguments for wrapping to [./wrapNeovim.nix](./wrapNeovim.nix).
