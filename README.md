# nixCats-nvim: A Lua-natic's kickstarter flake

### Attention: this branch is a work in progress.
> lazy.nvim wrapper util for nix is awaiting pull request [1259](https://github.com/folke/lazy.nvim/pull/1259)

## Features:
- Allows normal neovim configuration file scheme to be loaded from the nix store.
- Easy-to-use Nix Category system for many configurations in 1 repository! 
  - to use:
    - Make a new list in the set in the flake for it (i.e. if its a plugin you want to load on startup, put it in startupPlugins in categoryDefinitions)
    - enable the category for a particular neovim package in packageDefinitions set.
    - check for it in your neovim lua configuration with nixCats('attr.path.to.yourList')
- the nixCats command is your method of communicating with neovim from nix outside of installing plugins.
  - you can pass any extra info through the same set you define which categories you want to include.
  - it will be printed verbatim to a table in a lua file.
  - Not only will it be easily accessible anywhere from within neovim via the nixCats command, but also from your category definitions within nix as well for even more subcategory control. 
- Can be configured as a flake, nixos or home-manager module.
  - It can then be imported by someone else and reconfigured with the same options and exported again. And again. And again. You get it.
- blank flake template that can be initialized into your existing neovim config directory
- blank module template that can be initialized into your existing neovim config directory and moved to a home/system configuration
- `luaUtils` template containing the tools for integrating with pckr or lazy.
  - (currently uses my fork of lazy.nvim, pending PR for the 2 options added, https://github.com/folke/lazy.nvim/pull/1259)
- other templates containing examples of how to do other things with nixCats, and even one that implements the main init.lua of kickstart.nvim! (for a full list see [:help nixCats.installation_options](./nix/nixCatsHelp/installation.txt))
- Extensive in-editor help.

## Attention:
> You cannot launch nixCats with the nvim command. You may, however, launch it with anything else you would like to choose.

> This is a side effect of being able to install multiple simultaneous versions of the same version of nvim to the same user's PATH via a module such as home manager, something that would normally cause a collision error.

> The default launch name is the package name in the packageDefinitions set in flake.nix for that package. You may then make any other aliases that you please as long as they do not conflict.

> Nvim does not know about the wrapper script. Nvim is named `nvim` and is in a file in the store. It is still at `<store_path>/bin/nvim` and is aware of that. Thus, this should not cause any other issues.

## Introduction

This is a kickstarter style repo. It borrows a LOT of lua from [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim). It has mostly the same plugins.

This repo is not a lua showcase. You are meant to use your own lua once you understand what is going on.

It is aimed at people who know enough lua to comfortably proceed from a kickstarter level setup
who want to swap to using nix while still using lua for configuration.

For 95% of plugins and lsps, you won't need to do more than add plugin names to categories you make in flake.nix,
then configure in lua using lspconfig or the regular setup or config functions provided by the plugin.

The end result is it ends up being very much like using a neovim package manager,
except with the bonus of being able to install and set up more than just neovim plugins.

It also allows for easy project specific packaging using nixCats for all the cool direnv stuff.

You can nixCats('attr.path.to.value") to discover what nix categories you created are included in the current package.

Doing so allows you to define as many different packages as you want from the same config file.

nixCats can also send other info from nix to lua other than what categories are included, but that is the main use.

It then also exports as much stuff as possible for when you want to add some version of your own nixCats flake 
to a system nix config flake but maybe want to change something for that specific system without making a separate package for it if desired.

You should make use of the in-editor help at:

[:help nixCats](./nix/nixCatsHelp/nixCats.txt)

[:help nixCats.flake](./nix/nixCatsHelp/nixCatsFlake.txt)

The help can be viewed here on github but it is adviseable to use a nix shell to view it from within the editor.

Simply run ```nix shell github:BirdeeHub/nixCats-nvim``` and run nvim to read it.

This is because there is (reasonable) syntax highlighting for the code examples in the help when viewed within nvim.

There is about as much help as there is nix code in this entire project.

> An important note: if you add a file,
> nix will not package it unless you add it 
> to your git staging before you build it...
> So nvim wont be able to find it...
> So, run git add before you build,
> especially when using the wrapRc option.

Again, the lua is just [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim), with a couple changes. 

It has some stuff for nix, regular plugin setup functions as defined by the plugin rather than lazy,
and lspconfig instead of mason.

It works as a regular config folder without any nix too using the `luaUtils` template and [help: nixCats.luaUtils](./nix/nixCatsHelp/luaUtils.txt).

`luaUtils` contains the tools and advice to adapt your favorite package managers to give your nix setup the ultimate flexibility of trying to download all the dependencies for your overcomplicated config on a machine without using nix...

Luckily you have the ability to export a minimal package with whatever you want in it for this reason should you choose without needing a new config file.

It also has completion for the command line because I like that and also is multi file because I want to show the folders all work and because I like that too. The current version of the after directory just makes the numbers purple.

##### *The mission:*
- Replace nix package managers for plugins and lsps and keep everything else in the normal lua scheme. 
- 1 NORMAL nvim config directory, still allow project specific packaging.

##### *The solution:*
- Use nix to download the stuff and make it available to neovim.
- Include a nix store directory as a config folder, allowing all config to work like normal.
- Create nixCats by writing the packageDefinitions.categories set to a lua file so the lua may know what categories are packaged
-  You may optionally have your config in your normal directory as well via wrapRc setting,
   - You can copy your flake there and iterate on lua changes quicker while configuring (otherwise you have to `git add . && nix build` everytime because it loads from the store).
   - You will still be able to reference nixCats and the help should you do this.
- I ended up including a way to download via neovim plugin
    managers when away from nix because people seem to want
    a way to load their config without nix as an option.

#### These are the reasons I wanted to do it this way: 

- The setup instructions for new plugins are all in Lua so translating them is effort.
- I didn't want to be forced into creating a new lua file, 
    writing lua within nix, or creating hooks for a DSL for every new plugin.
- I wanted my neovim config to be neovim flavored 
    - (so that I can take advantage of all the neovim dev tools with minimal fuss)
- I still wanted my config to know what plugins and LSPs I included in the package
    so I created nixCats.

In terms of the nix code, you should not have to leave [flake.nix](./flake.nix) except OCCASIONALLY [customBuildsOverlay](./overlays/customBuildsOverlay.nix) when its not on nixpkgs and the standardPluginOverlay.

All config folders like `ftplugin/` and `after/` work as designed (see `:h rtp`), if you want lazy loading put it in `optionalPlugins` in a category in the flake and call `packadd` when you want it.
Although, it does specifically expect `init.lua` rather than `init.vim` at root level.

It runs on linux, mac, and WSL.
You will need nix with flakes enabled, git, a clipboard manager of some kind, and a terminal that supports bracketed paste. If you're not on linux you don't need to care what those last 2 things mean.

This is designed to give you package specific config, AND nixOS integration AND home manager integration, without ditching your lua. Or even leaving lua much at all.

That being said, definitely explore first while you understand the concept. It boils down to a few concepts.

#### *The idea*:
1. import flake as config file.
2. Sort categories.
3. Convert set that chooses the categories included verbatim to a lua table returned by nixCats.
4. export all the options possible

    The clever part is organizing it so that it is not unusable.

    It is entirely possible to use this flake and barely deal with the nix,
    and then make better use of the nix integration options
    as desired later for when you go to import the flake to your system flake/flakes

---

#### Basic usage:

(full usage covered in included help files, accessible here and inside neovim, but much better viewed in-editor)

You install the plugins/LSP/debugger/program using nix, by adding them to a category in the flake (or creating a new category for it!)

You may need to add their link to the flake inputs if they are not on nixpkgs already.

For specific tags or branches look at [this nix documentation](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#examples) and use that format in your flake input for it.

You then choose what categories to include in the package.

You then set them up in your lua, using the default methods to do so. No more translating to your package manager! (If you were using lazy, the opt section goes into the setup function in the lua)

You can optionally ask what categories you have in this package, whenever you use `nixCats('attr.path.to.value")`

If you encounter any build steps that are not well handled by nixpkgs, 
or you need to import a plugin straight from git that has a non-standard build step and no flake,
and need to do a custom definition, [customBuildsOverlay](./overlays/customBuildsOverlay.nix) is the place for it. 
Fair warning, this requires knowledge of nix derivations and should be needed only infrequently.
It will not be needed more than in any other method of configuring neovim via nix.

#### Installation:
see :help [nixCats.installation_options](./nix/nixCatsHelp/installation.txt)
for more info, including a list of templates available.

```bash
# everyone else:
# still use the in editor help.
# to begin:

# to test:
nix shell github:BirdeeHub/nixCats-nvim
#or
nix shell github:BirdeeHub/nixCats-nvim#nixCats
# If using zsh with extra regexing, be sure to escape the #
```
Now, typing `nixCats` `vim` or `vimcat` will open nixCats until you exit the shell.

Now that you are within an editor outfitted to edit a flake,
you can access the help for nixCats by typing `:help nixCats` and choosing one
of the options suggested by the auto-complete.

Now that you have access to the help and a nix lsp, to get started,
first exit neovim. (but not the nix shell!)

In a terminal, navigate to your nvim directory and run the following command:
```bash
  # flake template:
  nix flake init -t github:BirdeeHub/nixCats-nvim
  # module template:
  nix flake init -t github:BirdeeHub/nixCats-nvim#module
  # for package manager integration utilities for functionality without nix
  # added at lua/nixCatsUtils also run:
  nix flake init -t github:BirdeeHub/nixCats-nvim#luaUtils
  # If using zsh with extra regexing, be sure to escape the #
```
This will create an empty version of flake.nix (or systemCat.nix and homeCat.nix) for you to fill in,
along with an empty overlays directory for any custom builds from source
required, if any. It will directly import the utils and thus also the builder and
help from nixCats-nvim itself, keeping your configuration clean.

Re-enter the nixCats nvim version by typing `vim .` or `nixCats .` and take a look!
Reference the help and nixCats-nvim itself as a guide for importing your setup.
Typing `:help nixCats` will open up a list of help options for this flake via auto-complete.

You add plugins to the flake.nix, call whatever setup function is required by the plugin,
and use lspconfig to set up lsps. You may optionally choose to set up a plugin
only when that particular category is enabled in the current package by checking `nixCats('your.cats.name')` first.

It is a similar process to migrating to a new neovim plugin manager.

You are, of course, free to clone or fork nixCats-nvim instead
and migrate your stuff into it if you prefer.

Use the help and nixCats-nvim itself as an example.
The help will still be accessible in your version of the editor.

When you have your plugins added, you can build it using nix build and it
will build to a result directory, or nix profile install to install it to your
profile. Make sure you run `git add .` first as anything not staged will not
be added to the store and thus not be findable by either nix or neovim.
See nix documentation on how to use these commands further at:
[the nix command reference manual](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix)

When you have a working version, you can begin to explore the many
options made available for importing your new nix neovim configuration
into a nix system or home manager configuration.
There are *MANY*, thanks to the virtues of the category scheme of this flake.

It is made to be customized into your own portable nix neovim distribution 
with as many options as you wish, while requiring you to leave the normal
nvim configuration scheme as little as possible.

Think of it like, a build-your-own nixVim kit that doesn't
require you to know all about nix right away to get most of the benefits.

Further info:
see :help [nixCats.installation_options](./nix/nixCatsHelp/installation.txt)

There are several other templates.
They are designed to be used as examples for
importing versions of your nixCats into another existing configuration.

They are not particularly suited to being ran directly in your
nvim config folder like the first one was.
They are minimal examples of stuff that you can do.

You could more or less build your own nixVim in your flake by choosing
your categories carefully and referring to them within your lua.
And then the options would get automatically exported
for any way a nix user may want to set them.

All info I could manage to cover is covered in the included help files.
For this section,
see :help [nixCats.installation_options](./nix/nixCatsHelp/installation.txt)
and also :help [nixCats.flake.outputs.exports](./nix/nixCatsHelp/nixCatsFlake.txt)

With them you could partially or entirely add to, change, or recreate this flake.nix and/or the lua 
in another flake without having to redefine things (although you can only either add new lua or recreate it).

---

#### Drawbacks:

Specific to my project:

You cannot launch nvim with nvim and must choose an alias.
This is the trade off for installing multiple versions of the same version of nvim to the same user's PATH from a module, something that would normally cause a collision error.

General nix + nvim things:

Some vscode debuggers are not on nixpkgs so you have to build them in customBuildsOverlay. 
Let me know when you figure it out I'm kinda a noob still. [How to contribute](./CONTRIBUTING.md)
Mason does not work on nixOS although it does on other OS options.

#### Special mentions:

Many thanks to Quoteme for a great repo to teach me the basics of nix!!! I borrowed some code from it as well because I couldn't have written it better yet.

[./nix/utils/standardPluginOverlay.nix](./nix/utils/standardPluginOverlay.nix) is copy-pasted from [a section of Quoteme's repo.](https://github.com/Quoteme/neovim-flake/blob/34c47498114f43c243047bce680a9df66abfab18/flake.nix#L42C8-L42C8)

Thank you!!! It taught me both about an overlay's existence and how it works.

I also borrowed a decent amount of code from nixpkgs and made modifications.

#### Alternative / similar projects:

- [`kickstart.nvim`](https://github.com/nvim-lua/kickstart.nvim):
  This project was the start of my neovim journey and I would 100% suggest it over this one to anyone new to neovim.
  It does not use Nix to manage plugins. Use nixCats after this one if you want to move your version of kickstart to nix.
- [`kickstart-nix.nvim`](https://github.com/mrcjkb/kickstart-nix.nvim):
  A project that, like mine, also holds to a normal neovim config structure. It does not have have categories, exported options, or modules.
  It starts you at the basics, using the raw, wrapNeovimUnstable function and doesnt do much extra for you.
   - If mine has too many nix features for you, or you have no ambitions of doing multiple configurations in 1 config file, this is probably your next best starting point.
- [`NixVim`](https://github.com/nix-community/nixvim):
  A Neovim distribution configured using a NixOS module.
  Much more comparable to a neovim distribution like lazyVim or astrovim and the like, configuration entirely in nix.
- [`Luca's super simple`](https://github.com/Quoteme/neovim-flake):
  Definitely the simplest example I have seen thus far. I took it and ran with it, read a LOT of docs and nixpkgs source code and then made this.
  I mentioned it above in the special mentions. As someone with no exposure to functional programming, such a simple example was absolutely fantastic.
- [`neovim-flake`](https://github.com/jordanisaacs/neovim-flake):
  Configured using a Nix module DSL.
