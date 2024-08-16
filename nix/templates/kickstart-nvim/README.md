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
