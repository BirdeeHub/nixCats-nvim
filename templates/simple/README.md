# Simple

This is approximately as minimal of a configuration as possible without missing major functionality,
and is split up into multiple files for easy reading.

Just like the [`flakeless`](../flakeless) template it is a nix expression that returns a derivation containing
neovim plus your configuration that can be installed like any other package.

This configuration does not make much use of the category system. Everything is in 1 single `general` category.

It does not lazily load its plugins.

It does not set up backup download methods when not using nix.

If you are new to nvim and lua and maybe even nix, and everything else is too confusing, this may help!

You can run `nix-build` on it,

or import it from any nix code like

`import ./thisdir { inherit pkgs; inherit (inputs) nixCats; }`

or even like this if you are using an impure configuration or the repl

`import ./thisdir {}`
