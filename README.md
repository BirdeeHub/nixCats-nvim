<div align="center">

# [nixCats](https://nixcats.org)

for the Lua-natic's Neovim config on Nix

</div>

<br/>

- A Neovim package manager written in Nix.

- **Nix is for downloading. Lua is for configuring.**
  Keep your existing Lua config directory,
  while Nix provides any dependency in a contained and reproducible way.
  Configure all downloads from a single Nix file.

- **Multiple Neovim executables.**
  Easily output multiple configured packages that are variations of your main config.

- **Best of both worlds.**
  Use the Nix Store for full reproducibility and `nix run`,
  or switch to live reloading with `wrapRc = false`.
  Or make one package for each.
  
- **No need for Lua in Nix strings.**
  The name is short for 'Nix Categories':
  define arbitrary categories of dependencies in Nix, and interact with them transparently from Lua.
  
- **Integrates with NixOS or Home Manager,**
  but buildable separately.

- **Build it your way.**
  Configurable as a flake, a derivation or a module,
  or even entirely via calling the override function on a nixCats based package.
  It can then be imported and reconfigured without duplication and exported again. And again. and again.

- **Extensive in-editor help** via [:help nixCats](https://nixcats.org/TOC.html).

## Table of Contents

1. [Introduction](#intro)
2. [Getting Started](#getting-started)
3. [Special Mentions](#mentions)

- [nixcats.org: Table of Contents](https://nixcats.org/TOC.html)

---

## Introduction <a name="intro"></a>

The goal of `nixCats` is to make it as easy as possible to interact with the normal configuration scheme,
while using Nix to install things and add useful meta-features.
This is the opposite approach to projects like [nixvim](#nixvim) or [nvf](#nvf),
which aim to "nixify" Neovim as much as possible.

The end result ends up being very comparable to
&mdash; if not better than &mdash;
using a regular Neovim package manager + [Mason](#mason).
And it is much more portable.

It also avoids falling into the trap of trying to make a module for every plugin somebody might want to use.
The Neovim plugin ecosystem is very large, and updates are often.
This leads to a lot of time spent doing and maintaining simple translations of Lua options into Nix.
Or worse, lagging behind on new features due to having to reapply them for each plugin.

Instead, `nixCats` aims for a higher quality experience interacting with the plugin ecosystem as it is,
and it only needs a single Nix file to effectively manage your Neovim installation.
In addition, you can still make use of the nice features and Lua autocompletion usual for a Neovim configuration.

> But what if you want to pass information from Nix to the rest of your Neovim configuration?

This is where Home Manager and `pkgs.wrapNeovim` start to fall short.
It is not uncommon to see a mess of global variables written in Nix strings,
and a bunch of files called via `dofile` that are not properly detected by Neovim tooling with these methods.
To pass info from Nix to Lua, you must `''${interpolate a string}'';`.
So you need to write some Lua in strings in Nix.
Right?

Not anymore!

The Nix Category scheme is simple:

1. Make a new list in the correct section of [`categoryDefinitions`](https://nixcats.org/nixCats_format.html#nixCats.flake.outputs.categories).
   For example, make a list in the `startupPlugins` set for plugins that load on startup.

2. Enable that category for the desired Neovim package in [`packageDefinitions`](https://nixcats.org/nixCats_format.html#nixCats.flake.outputs.packageDefinitions).

3. Check for it in your Neovim Lua configuration with [`nixCats('attr.path.to.yourList')`](https://nixcats.org/nixCats_plugin.html).

Your package definitions are not only how you enable categories per package,
but they also allow you to pass arbitrary information to Neovim, and grab it just as easily.

Simply put your Nix data into the set in your package definitions, and access it in Lua as a Lua data structure.

You can pass anything that is not an _uncalled_ Nix function. Lua interpreters can't run Nix code.

No more wondering how you are going to get info into Lua without ruining your normal Neovim directory by writing Lua in nix strings!

- If you like the normal Neovim configuration scheme,
  but want your config to be runnable via `nix run` and have an easier time dealing with dependency issues,
  this repo is for you.

- Even if you don't use it for downloading plugins at all,
  preferring to use lazy and Mason and deal with issues as they arise,
  this scheme will have useful things for you.
  
## Getting Started <a name="getting-started"></a>

So many [templates](https://nixcats.org/nixCats_templates.html)!

How do I know which of them to pick? How do I install the thing I get from that?

The [installation guide](https://nixcats.org/nixCats_installation.html) is here to help!

The first thing it will guide you through is how to decide on a [template](https://nixcats.org/nixCats_templates.html).

Don't worry, the modules and the flake templates have very similar structure.
So if you pick one that doesn't fit you, it will be easy to swap to one that does.

It will then walk you through a 100 line [overview](https://nixcats.org/nixCats_installation.html#nixCats.overview)
detailing each of the parts of `nixCats` you will interact with most.

All config folders like `ftplugin/`, `pack/` and `after/` work as designed (see `:h rtp`).

If you want lazy loading put it in `optionalPlugins`
in your [`categoryDefinitions`](https://nixcats.org/nixCats_format.html#nixCats.flake.outputs.categories)
and call `vim.cmd('packadd <pluginName>')` from an autocommand or keybind when you want it.

For lazy loading in your configuration, I strongly recommend using [`lze`](https://github.com/BirdeeHub/lze) or [`lz.n`](https://github.com/nvim-neorocks/lz.n).

The main example configuration [here](https://github.com/BirdeeHub/nixCats-nvim/tree/main/templates/example) uses `lze`.
They are not package managers, and work within the normal Neovim plugin system, just like `nixCats` does.
This makes them much more suitable for managing lazy loading when using Nix.

[`lazy.nvim`](https://github.com/folke/lazy.nvim) is known for not playing well in conjunction with other package managers,
so using it will require a little bit of extra setup compared to the 2 above options.

However `nixCats` provides a simple to use [lazy.nvim wrapper](https://nixcats.org/nixCats_luaUtils.html) wrapper that can be used if desired.

It is demonstrated to good effect in the [kickstart-nvim](https://github.com/BirdeeHub/nixCats-nvim/blob/main/templates/kickstart-nvim) and [LazyVim](https://github.com/BirdeeHub/nixCats-nvim/blob/main/templates/LazyVim) templates.

Keep in mind, `lazy.nvim` will prevent Nix from loading any plugins
unless you also add it to a `lazy.nvim` plugin spec


### Important note on package names

You may launch your Neovim built via `nixCats` with any name you would like to choose.
The default launch name is given by package name in [`packageDefinitions`](https://nixcats.org/nixCats_format.html#nixCats.flake.outputs.packageDefinitions).

In particular, the desktop file follows the package name, so programs like git will only know where to look if you set that as your `$EDITOR` variable.

You may then make any other aliases that you please as long as they do not conflict.
If you try to install conflicting aliases to your path via `home.packages` or `environment.systemPackages`, you will get a collision error.

Neovim does not know about the wrapper script.
It is still at `<store_path>/bin/nvim` and is aware of that.
Therefore this should not cause any issues beyond how Neovim is normally wrapped in `nixpkgs`.

**Remember to change your `$EDITOR` variable if you named your package something other than `nvim`!**

### Important note on flakes

Make sure you run `git add .` first
as anything not staged will not be added to the store
and thus not be findable by either Nix or Neovim.

See Nix documentation on how to use the command line commands further at:
[the Nix command reference manual](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix)

Also, familiarize yourself with the [flake schema](https://nixos.wiki/wiki/Flakes)

This knowledge will be useful when installing flake based nixCats configurations into your main configuration.

### [Mason](https://github.com/williamboman/mason.nvim) <a name="mason"></a>

Mason does not readily work on NixOS (although it does on other OS options).

Luckily you also don't need it.

All Mason does is download it to your path, and call [`lspconfig`](https://github.com/neovim/nvim-lspconfig) on the result.

You can install them via the `lspsAndRuntimeDeps` field in your [`categoryDefinitions`](https://nixcats.org/nixCats_format.html#nixCats.flake.outputs.categories).

Then call [`lspconfig`](https://github.com/neovim/nvim-lspconfig) yourself in your Lua.

The
[example config](https://github.com/BirdeeHub/nixCats-nvim/blob/main/templates/example/lua/myLuaConf/LSPs/init.lua)
and
[:h nixCats.LSPs](https://nixcats.org/nix_LSPS.html)
show examples of this, and the examples still run Mason when Nix wasn't used to load the config!

You could force it to work. NixCats has the ability to bundle any type of dependency it might need.

Sometimes it can be hard to tell what dependency the error is even asking for though.

---

### Special mentions <a name="mentions"></a>

#### For getting me started

Many thanks to [Quoteme](https://github.com/Quoteme/neovim-flake/blob/34c47498114f43c243047bce680a9df66abfab18/flake.nix) for a great repo to teach me the basics of Nix!!!
I borrowed some code from it as well because I couldn't have written it better.

Definitely the simplest example I have seen thus far.

As someone with no prior exposure to functional programming, such a simple example was absolutely fantastic.

[utils.standardPluginOverlay](https://github.com/BirdeeHub/nixCats-nvim/blob/main/utils/autoPluginOverlay.nix)
is copy-pasted from
[a section of Quoteme's repo.](https://github.com/Quoteme/neovim-flake/blob/34c47498114f43c243047bce680a9df66abfab18/flake.nix#L42C8-L42C8)

Thank you!!!
I literally did not even know what an overlay was yet and you taught me!

I also borrowed code from [nixpkgs](https://github.com/NixOS/nixpkgs) and made modifications and improvements to better fit nixCats.

## Alternative projects <a name="alternatives"></a>

- [`kickstart.nvim`](https://github.com/nvim-lua/kickstart.nvim):
  This project was the start of my Neovim journey
  and I would 100% suggest it over this one to anyone who doesn't use NixOS and is new to Neovim.
  It does not use Nix to manage plugins, and uses mason.

- [`kickstart-nix.nvim`](https://github.com/mrcjkb/kickstart-nix.nvim):
  A project that, like this one, also holds to a normal Neovim config structure.
  It is a template tutorial on loading a directory using the `pkgs.wrapNeovimUnstable` function from nixpkgs.

- [`nixPatch-nvim`](https://github.com/NicoElbers/nixPatch-nvim):
  Focused specifically for lazy.nvim.
  A cool unique concept, uses a Zig program to
  parse lazy.nvim definitions to replace urls with the plugins you put in your Nix lists at build time.
  Usage is somewhat similar to the lazy.nvim wrapper of nixCats in a standalone flake template.
  It obviously also does not have the categories, modules, multiple packages, the overriding scheme, etc.

- [`NixVim`](https://github.com/nix-community/nixvim): <a name="nixvim"></a>
  A Neovim module scheme semi-comparable to Home Manager for Neovim.
  They try to have a module for as many packages as they can and do a great job,
  but you can always fall back to writing lua in nix strings if something is missing.

- [`nvf`](https://github.com/NotAShelf/nvf): <a name="nvf"></a>
  An alternative to NixVim. Another project that attempts to "nixify" everything.
