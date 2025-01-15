<div align="center">

# [nixCats](https://nixcats.org)

for the Lua-natic's Neovim config on Nix

</div>

<br/>

- A Neovim package manager written in Nix.

- **Nix is for downloading. Lua is for configuring.**
  Keep your existing Lua config directory,
  while Nix provides any dependency in a contained and reproducible way.

- **Multiple Neovim executables.**
  Easily output multiple configured packages that are variations of your main config.

- **Best of both worlds.**
  Use the Nix Store for full reproducibility and `nix run`,
  or switch to live reloading with `wrapRc = false`.
  Or make one package for each.
  
- **No need for Lua in Nix strings.**
  The name is short for 'Nix Categories':
  define arbitrary categories of dependencies in Nix, and interact them straight from Lua.
  
- **Integrates with NixOS or Home Manager,** but buildable separately.
  Configure in a flake, as a derivation, or as a module.

## Table of Contents

1. [Introduction](#intro)
2. [Getting Started](#getting-started)
3. [Installation](#installation)
4. [Features](#features)
5. [Extra Information](#outro)
6. [Alternative / Similar Projects](#alternatives)
- [nixcats.org: Table of Contents](https://nixcats.org/TOC.html)

---

## Introduction <a name="intro"></a>

The goal of `nixCats` is to make it as easy as possible to interact with the normal configuration scheme,
while using Nix to install things and add useful meta-features.
This is the opposite approach to projects like [nixvim](#nixvim),
which aim to Nixify Neovim as much as possible.

The end result ends up being very comparable to
&mdash; if not better &mdash;
using a regular Neovim package manager with
[Mason](https://github.com/williamboman/mason.nvim).
And it is much more portable.

It also avoids falling into the trap of trying to make a module for every plugin somebody might want to use.
The Neovim plugin ecosystem is very large, and updates are often.
This leads to a lot of time spent doing and maintaining simple translations of Lua options into Nix.

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

- If you like the normal Neovim configuration scheme,
  but want your config to be runnable via `nix run` and have an easier time dealing with dependency issues,
  this repo is for you.

- Even if you don't use it for downloading plugins at all,
  preferring to use lazy and Mason and deal with issues as they arise,
  this scheme will have useful things for you.
  
## Getting Started <a name="getting-started"></a>

The example Neovim config [here](https://github.com/BirdeeHub/nixCats-nvim/tree/main/templates/example) is a great example of how to use `nixCats` for yourself.

You should stop and take a moment to read the [overview](https://nixcats.org/nixCats_installation.html#nixCats.overview)
while looking at the above example configuration and/or the [default template](https://github.com/BirdeeHub/nixCats-nvim/blob/main/templates/fresh/flake.nix) to get a feel of what this package management scheme has to offer!

Everything in
[./templates](https://github.com/BirdeeHub/nixCats-nvim/tree/main/templates)
is also either a starter template, or more examples.
The
[in-editor help](https://nixcats.org/TOC.html)
will be available in any Neovim that uses the `nixCats` builder, or at the
[website](https://nixcats.org/)!
There is significantly more help and example in this repository than there is actual functional code for the nixCats wrapper.

When you are ready, start with a
[template](https://github.com/BirdeeHub/nixCats-nvim/tree/main/templates)
and include your normal configuration,
and refer back here or to the in-editor help or the other templates for guidance!

All config folders like `ftplugin/`, `pack/` and `after/` work as designed (see `:h rtp`),
if you want lazy loading put it in `optionalPlugins` in a category in the flake and call `vim.cmd('packadd <pluginName>')` from an autocommand or keybind when you want it.

For lazy loading in your configuration, I strongly recommend using [lze](https://github.com/BirdeeHub/lze) or [lz.n](https://github.com/nvim-neorocks/lz.n).
The main example configuration [here](https://github.com/BirdeeHub/nixCats-nvim/tree/main/templates/example) uses `lze`.
They are not package managers, and work within the normal Neovim plugin system, just like `nixCats` does.

However there is a [lazy.nvim](#outro) wrapper that can be used if desired,
but follow that link and read the info about it before deciding to take that route.
`lazy.nvim` is known for not playing well in conjunction with other package managers,
so using it will require a little bit of extra setup compared to the 2 above options.

## Attention <a name="attention"></a>

> You may launch your Neovim built via nixCats with any name you would like to choose.

> The default launch name is the package name in the packageDefinitions set in flake.nix for that package.
> You may then make any other aliases that you please as long as they do not conflict.

> This means that your $EDITOR variable should match the name in your packageDefinitions set in flake.nix so that stuff like git opens the right thing, because that is what the desktop file is called.

> If your aliases conflict and you try to install them both to your path via home.packages or environment.systemPackages, it will throw a collision error.

> Nvim does not know about the wrapper script.
> It is still at `<store_path>/bin/nvim` and is aware of that.
> Thus, this should not cause any issues beyond the way nvim is normally wrapped via the wrappers in nixpkgs.

##### (remember to change your $EDITOR variable if you named your package something other than nvim!)


## Installation <a name="installation"></a>

See :help
[nixCats.installation_options](https://nixcats.org/nixCats_installation.html#nixCats.installation_options)
for more info,
including a list of templates available
(as well as a 100 line overview of what nixCats is and how to use it)

The installation info here is simply a repetition of the info there,
and I would suggest viewing it there instead.

- to test:
```bash
nix shell github:BirdeeHub/nixCats-nvim?dir=templates/example
```

Now, typing `nixCats` will open nixCats until you exit the shell.

Now that you are within an editor outfitted to edit a flake,
you can access the help for nixCats by typing `:help nixCats`
and choosing one of the options suggested by the auto-complete.

Now that you have access to the help and a Nix LSP, to get started,
first exit Neovim.
(but not the Nix shell!)

In a terminal, navigate to your nvim directory
and run your choice of the following commands at the top level of your Neovim config:

(don't worry! It doesn't overwrite anything!)

- standalone flake template:
```bash
  nix flake init -t github:BirdeeHub/nixCats-nvim
```

- nixExpressionFlakeOutputs template:
  - for more advanced Nix users
  - the outputs function of the flake template but as its own file
    callable with import ./the/dir { inherit inputs; }
    to recieve all normal flake outputs.
    Best used after the default template to integrate your new Neovim config
    into an existing flake-based configuration's repository

```bash
  nix flake init -t github:BirdeeHub/nixCats-nvim#nixExpressionFlakeOutputs
```

> If using Zsh with extra regexing, be sure to escape the #

There are others which _could_ be used to create a new base config,
but these will be the simplest to start with,
and don't inherit any previous config by default.

All such templates have more or less the same options, so converting between them is easy.

To add utilities for functionality without Nix
at `lua/nixCatsUtils`, also run the following
at the top level of your Neovim config:
```bash
  nix flake init -t github:BirdeeHub/nixCats-nvim#luaUtils
```

> contains things like "is this Nix?" "do this if not Nix, else do that"

> Needs to be in your config at lua/nixCatsUtils,
> because if you dont use Nix to load Neovim,
> nixCats (obviously) can't provide you with anything from Nix!

The starter templates will create an empty version of
[flake.nix](https://github.com/BirdeeHub/nixCats-nvim/blob/main/templates/fresh/flake.nix)
(or
[default.nix](https://github.com/BirdeeHub/nixCats-nvim/blob/main/templates/nixExpressionFlakeOutputs/default.nix))
for you to fill in.

If you are unfamiliar with Neovim and want a ready-made starter config,
you should instead use the following template:

```bash
  nix flake init -t github:BirdeeHub/nixCats-nvim#example
```

All templates will import the utils set and thus also the builder
and help from nixCats-nvim itself.

If you added the luaUtils template, you should have that now too at lua/nixCatsUtils.

Re-enter the nixCats nvim version by typing `nixCats .` and take a look!
Reference the help and nixCats-nvim itself as a guide for importing your setup.
Typing `:help nixCats` without hitting enter will open up a list of help options for this scheme via auto-complete.

You add plugins to the flake.nix,
call whatever setup function is required by the plugin wherever you want,
and use lspconfig to set up LSPs.
You may optionally choose to set up a plugin
only when that particular category is enabled in the current package
by checking `nixCats('your.cats.name')` first.

see
[:h nixCats](https://nixcats.org/nixCats_plugin.html)
for help with the nixCats Lua plugin.

It is a similar process to migrating to a new Neovim plugin manager.
Because you are.

Use a template and put the plugin names into the main Nix file provided.

You can import them from nixpkgs or straight from your inputs via a convenience overlay
[:h nixCats.flake.inputs](https://nixcats.org/nixCats_format.html#nixCats.flake.inputs)

Then configure in Lua.

Use the help, and the example config
[here](https://github.com/BirdeeHub/nixCats-nvim/blob/main/templates/example).
The help will still be accessible in your version of the editor.

When you have your plugins added,
you can build it using `nix build` and it will build to a result directory,
or `nix profile` install to install it to your profile.
Make sure you run `git add .` first
as anything not staged will not be added to the store
and thus not be findable by either Nix or Neovim.
See Nix documentation on how to use these commands further at:
[the Nix command reference manual](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix)

When you have a working version,
you can begin to explore the many options made available for
importing your new Nix Neovim configuration into a Nix system or Home Manager configuration.
There are *MANY*, thanks to the virtues of the category scheme of this flake.

---

## Features <a name="features"></a>

- Allows normal Neovim configuration file scheme to be loaded from the Nix store.

- Configure all downloads from a single Nix file,
  use a regular Neovim config scheme with full visibility of your Nix!

- Easy-to-use Nix Category system for many configurations in 1 repository!
  - to use:
    - Make a new list in the set in the flake for it
      (i.e. if its a plugin you want to load on startup, put it in startupPlugins in categoryDefinitions)
    - enable the category for a particular Neovim package in packageDefinitions set.
    - check for it in your Neovim Lua configuration with `nixCats('attr.path.to.yourList')`

- the [nixCats command](https://nixcats.org/nixCats_plugin.html)
  is your method of communicating with Neovim from Nix outside of installing plugins.
  - you can pass any extra info through the same set you define which categories you want to include.
  - it will be printed verbatim to a table in a Lua file.
  - Not only will it be easily accessible anywhere from within Neovim via the nixCats command,
    but also from your category definitions within Nix as well for even more subcategory control.

- Can be configured as a:
  - flake
  - in another flake
  - as a NixOS or Home Manager module
  - entirely via calling the override function on a nixCats based package.
  - It can then be imported and reconfigured without duplication and exported again. And again. and again.

- blank flake [template](https://github.com/BirdeeHub/nixCats-nvim/blob/main/templates/fresh)
  that can be  initialized into your existing Neovim config directory to get you started!
  - because you can mess around with it in its own repo in any directory,
    this is the lowest barrier of entry,
    and transitions well into any other template if desired.

- blank [template](https://github.com/BirdeeHub/nixCats-nvim/blob/main/templates/nixExpressionFlakeOutputs)
  that is called as a Nix expression from any other flake.
  - It is simply the outputs function of the flake template above but as its own file,
    callable with your system's flake inputs,
    and returning all the normal flake outputs the other would have.
  - great for integrating into a system config
    and still being able to output the finished packages from your system flake.

- blank override [template](https://github.com/BirdeeHub/nixCats-nvim/blob/main/templates/overwrite)
  that achieves functionality the same as the above two,
  but entirely via using the override function on the example nvim package from the nixCats flake.

- blank module [template](https://github.com/BirdeeHub/nixCats-nvim/blob/main/templates/module)
  that exports the configuration of your packages in module form,
  inherits values from your other template and can be reconfigured.
  Similar to override, but as a module.

- luaUtils [template](https://github.com/BirdeeHub/nixCats-nvim/blob/main/templates/luaUtils)
  template containing the tools for detecting if Nix loaded your config or not,
  and integrating with lazy.nvim or other plugin managers.
  - this is an optional, additional template.
  - proper useage of this template can yield a configuration that you can use both with or without Nix.
  - contains the lazy.nvim wrapper.

- other templates containing examples of how to do other things with nixCats,
  and even one that implements the entirety of
  [kickstart.nvim](https://github.com/BirdeeHub/nixCats-nvim/blob/main/templates/kickstart-nvim)
  using the lazy wrapper!
  (for a full list see
  [:help nixCats.templates](https://nixcats.org/nixCats_installation.html#nixCats.templates))

- ability to call override as many times as you like to fully recustomize or combine packages

- [Extensive in-editor help.](https://nixcats.org/TOC.html)

- I mentioned the templates already but if you want to see them all on GitHub they are here:
  [templates](https://github.com/BirdeeHub/nixCats-nvim/blob/main/templates)

## Extra Information: <a name="outro"></a>

### Challenges

#### [Mason](https://github.com/williamboman/mason.nvim)

Mason does not work on NixOS although it does on other OS options.

Luckily you also don't need it.
All Mason does is download it to your path, and call lspconfig on the result.

You can do this via the lspsAndRuntimeDeps field in nixCats,
and then calling lspconfig yourself.

The
[example config](https://github.com/BirdeeHub/nixCats-nvim/blob/main/templates/example/lua/myLuaConf/LSPs/init.lua)
and
[:h nixCats.LSPs](https://nixcats.org/nix_LSPS.html)
show examples of this, and the examples still run Mason when Nix wasn't used to load the config!

That way you can just add the LSP to the list in Nix,
add the same Lua config you would have for Mason,
and move on.

However you can make it work with SharedLibraries and lspsAndRuntimeDeps options
if you choose to not use those fields for their intended purpose!
Sometimes it can be hard to tell what dependency the error is even asking for though.

---

#### [lazy.nvim](https://github.com/folke/lazy.nvim)

`lze` and `lz.n`, unlike `lazy.nvim`, are not plugin managers.
They stick to the task of lazy loading and do it well, with a very similar plugin spec style to `lazy.nvim`
They fit in much better with all Nix solutions for nvim than `lazy.nvim` does.

If you do decide to use `lazy.nvim`, consider using the `lazy.nvim` wrapper
[in luaUtils template](https://github.com/BirdeeHub/nixCats-nvim/blob/main/templates/luaUtils/lua/nixCatsUtils)
documented in
[:h luaUtils](https://nixcats.org/nixCats_luaUtils.html#nixCats.luaUtils.lazy)
and
[demonstrated here](https://github.com/BirdeeHub/nixCats-nvim/blob/main/templates/kickstart-nvim).
The luaUtils template also contains other simple tools that will help
if you want your configuration to still load without Nix involved in any way.
You likely will not need to do that though.
The Nix package manager runs on any linux, Mac, or WSL.

Lazy.nvim works but unless you tell it not to reset the RTP
you will lose your config directory and treesitter parsers.

There is an included wrapper that you can use to do this
and also stop it from downloading stuff you already downloaded via Nix.

You call that instead.
It takes 1 extra argument, and then the 2 standard lazy.setup arguments.

The first argument is the path to `lazy.nvim` downloaded from Nix.
If this is `nil` it will download lazy the normal way instead.

You can fetch this value with `nixCats.pawsible({"allPlugins", "start", "lazy.nvim" })`
unless your `lazy.nvim` has been given a different name.

Then in your specs, simply fix any names that were different from Nix
(see `:NixCats pawsible` for the new values)
and disable build statements while on Nix with the `require('nixCatsUtils').lazyAdd` function

Obviously if you chose to still download the plugins via lazy you would want to keep the build statements
and instead add any non-plugin dependencies they need to your Nix.

Keep in mind, `lazy.nvim` will prevent Nix from loading any plugins
unless you also add it to a lazy plugin spec

I highly recommend using one of the following 2 projects for lazy loading instead:

#### [lz.n](https://github.com/nvim-neorocks/lz.n)

`lz.n` exists and due to it working within the normal Neovim plugin management scheme is better suited for managining lazy loading on Nix-based configurations than lazy.nvim is.

#### [lze](https://github.com/BirdeeHub/lze)

`lze` is my take on what `lz.n` did,
after spending a decent amount of time contributing to `lz.n` to begin with.

I preferred a different design to the management of state and custom handlers, and quite like the result.
The main example configuration in this repo uses it for lazy loading.

---

### Special mentions

#### For getting me started

Many thanks to Quoteme for a great repo to teach me the basics of Nix!!!
I borrowed some code from it as well because I couldn't have written it better.

[utils.standardPluginOverlay](https://github.com/BirdeeHub/nixCats-nvim/blob/main/utils/autoPluginOverlay.nix)
is copy-pasted from
[a section of Quoteme's repo.](https://github.com/Quoteme/neovim-flake/blob/34c47498114f43c243047bce680a9df66abfab18/flake.nix#L42C8-L42C8)

Thank you!!!
I literally did not even know what an overlay was yet and you taught me!

I also borrowed code from nixpkgs and made modifications and improvements to better fit nixCats.

## Alternative / similar projects <a name="alternatives"></a>

- [`kickstart.nvim`](https://github.com/nvim-lua/kickstart.nvim):
  This project was the start of my Neovim journey
  and I would 100% suggest it over this one to anyone new to Neovim.
  It does not use Nix to manage plugins.
  Use nixCats after this one if you want to move your version of kickstart to Nix.

- [`kickstart-nix.nvim`](https://github.com/mrcjkb/kickstart-nix.nvim):
  A project that, like this one, also holds to a normal Neovim config structure.
  It is a template tutorial on using the raw, wrapNeovimUnstable function with no modifications.
  If nixCats feels like it is too far from the metal on the Nix side of things for you
  and you want to build from the ground up,
  and you still want to be able to run it in Nix shells,
  this is the way to go.

- [`NixVim`](https://github.com/nix-community/nixvim): <a name="nixvim"></a>
  A Neovim module scheme semi-comparable to Home Manager for Neovim.
  They try to have a module for as many packages as they can and do a great job,
  but you can always fall back to the programs.neovim syntax if something is missing.

- [`Luca's super simple`](https://github.com/Quoteme/neovim-flake):
  Definitely the simplest example I have seen thus far.
  I took it and ran with it, read a LOT of docs and nixpkgs source code and then made this.
  I mentioned it above in the special mentions.
  As someone with no exposure to functional programming, such a simple example was absolutely fantastic.

- [`nixPatch-nvim`](https://github.com/NicoElbers/nixPatch-nvim):
  Focused specifically for lazy.nvim.
  A cool unique concept, uses a Zig program to
  parse lazy.nvim definitions to replace urls with the plugins you put in your Nix lists at build time.
  Usage is somewhat similar to the lazy.nvim wrapper of nixCats in a standalone flake template.
  It obviously also does not have the categories, modules, multiple packages, the overriding scheme, etc.
