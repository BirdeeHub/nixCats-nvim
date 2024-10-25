# This is the help for the nixCats lazy wrapper

Or well, most of the help for it. There is also help for it at [:h nixCats.luaUtils](https://nixcats.org/nixCats_luaUtils.html)

It is the entirety of [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) with very few changes, but uses nixCats to download everything

enter a new directory then run:

`nix flake init -t github:BirdeeHub/nixCats-nvim#kickstart-nvim`

then to build, `nix build .`

and the result will be found at `./result/bin/nvim`

It also can work without any nix whatsoever.
It has been adapted such that it works either way!

All notes about the lazy wrapper are in comments that begin with the string: `NOTE: nixCats:` so to find all of the info, search for that.

One other note.

If you install your grammars via `lazy.nvim` rather than `nix`, you will need to add a c compiler to your `lspsAndRuntimeDeps` section in your `categoryDefinitions`

If you install your grammars via nix, the only methods supported via the `lazy.nvim` wrapper are the following.

Summary: as long as `pkgs.neovimUtils.grammarToPlugin` is called on it somehow, it will work.

Any other ways will still work in nixCats, but not when using the lazy wrapper, because the lazy wrapper has to add them back to the runtimepath.

```nix
pkgs.vimPlugins.nvim-treesitter.withAllGrammars
# or
pkgs.vimPlugins.nvim-treesitter.withPlugins (plugins: with plugins; [
  nix
  lua
  # etc...
]);
# or
pkgs.vimPlugins.nvim-treesitter.withPlugins (plugins: pkgs.vimPlugins.nvim-treesitter.allGrammars)
# or
builtins.attrValues pkgs.vimPlugins.nvim-treesitter.grammarPlugins
# or
pkgs.neovimUtils.grammarToPlugin pkgs.tree-sitter-grammars.somegrammar
```
