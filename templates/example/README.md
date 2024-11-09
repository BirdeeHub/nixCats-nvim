This directory contains a somewhat idiomatic[^1] `nixCats` config using [`lze`](https://github.com/BirdeeHub/lze) for lazy loading. (with a backup downloading method via `paq` and `mason` in case you want to load the directory without using `nix` at all)

While the `lazy.nvim` wrapper does exist, this template shows a suggested way of using `nixCats`.

It is a decent starting point to using `neovim`, think `kickstart-nvim` but using `nix` INSTEAD OF `lazy.nvim` and `mason`,
rather than in addition. It is also spread out across more files instead of one big file.

It is not a perfect config, nor do I claim it to be, but it is decent, and you are meant to make it yours. `NixCats` is just the nix-based package manager, and its associated [lua plugin](https://nixcats.org/nixCats_plugin.html).

Using it this way will have the most simple feel to use, as opposed to dealing with `lazy.nvim` disabling all plugin loading it doesn't do itself via a wrapper.

There are many ways to use `nixCats`, and all are correct.

But hopefully this will be a good example of 3 things:
- how it looks like to use `nixCats` as your only package manager while on nix,
- what it looks like to use something other than `lazy.nvim` for lazy-loading
- how to make a config that works both with and without nix.

If you have no idea what I'm talking about in the next section, see [:h 'rtp'](https://neovim.io/doc/user/options.html#'rtp') 

I only use the `lua` directory, and also the `after/plugin` directory to prove that it works.
You may wish to use `ftplugin` or `plugin` directories instead to have an even more modular config.

You are encouraged to do so, but I didn't do it here.
Even `pack/*/{start, opt}` in your config works, so do your thing.

[^1]: where idiomatic mostly means that it doesn't use `lazy.nvim`, and uses `nixCats` to download everything,
    and makes sure to check if its category was enabled before it loads a plugin,
    and makes use of the [luaUtils template](https://github.com/BirdeeHub/nixCats-nvim/tree/main/templates/luaUtils/lua/nixCatsUtils)
    (see :h [nixCats.luaUtils](https://nixcats.org/nixCats_luaUtils.html)),
    and uses [`lze`](https://github.com/BirdeeHub/lze).
