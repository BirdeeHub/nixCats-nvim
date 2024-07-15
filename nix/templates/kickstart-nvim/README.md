# This is the help for the nixCats lazy wrapper

It is the entirety of [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) with very few changes, but uses nixCats to download everything

enter a new directory then run:

`nix flake init -t github:BirdeeHub/nixCats-nvim#kickstart-nvim`

then to build, `nix build .`

and the result will be found at `./result/bin/nixCats` (or with a different name if you changed it before building)

It also can work without any nix whatsoever.
It has been adapted such that it works either way!
