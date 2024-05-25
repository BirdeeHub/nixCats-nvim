# nixCats-nvim: for the Lua-natic's neovim config on nix!

### Philosophy:

This is a neovim configuration scheme for new and advanced nix users alike, and you will find all the normal options here and then some.

- If you like your normal nvim configuration, but want to do all that cool direnv stuff you heard about with nix?

- You want to make a nix-based neovim distribution out of your normal neovim distribution and export advanced options to your nix users without having to do all the nix wiring for that yourself?

- You are new to nix and just want to initialize a template into your existing neovim directory, add a few programs and plugins to a list and have it just work, but want to make sure you arent backed into any corners later? And be guided along the way by extensive IN-EDITOR DOCUMENTATION?

Then this is your place to start!

The neovim config here is an example of how to use nixCats for yourself. When you are ready, start with a template and include your normal configuration, and refer back here or to the help for guidance!

##### (just remember to change your $EDITOR variable, the reason why is explained below in the section marked [Attention](#attention))

This project is a heavily modified version of the wrapNeovim/wrapNeovimUnstable functions provided by nixpkgs, to allow you to get right into a working and full-featured, nix-integrated setup based on your old configuration as quickly as possible without making sacrifices in your nix that you will need to refactor out later.

All loading can be done from [flake.nix](./flake.nix), with the option of custom overlays for specifc things there should you need it (rare!). Alternatively, you could import it as a module (nixos and/or home-manager)! It works the same way with either method. Then configure in the normal neovim scheme.

The first main feature is the nixCats messaging system, which means you will not need to write ANY lua within your nix files (although you still can), and thus can use all the neovim tools like neodev that make configuring it so wonderful when configuring in your normal ~/.config/nvim

Nix is for downloading and should stay for downloading. Your lua just needs to know what it was built with and where that is.

There is no live updating from nix. Nix runs, it installs your stuff, and then it does nothing. Therefore, there is no reason you can't just write your data to a lua table in a file.

And thus nixCats was born. A system for doing just that in an effective and organized manner. It can pass anything other than nix functions, because again, nix is done by the time any lua ever executes.

The second main feature is the category system, which allows you to enable and disable categories of nvim dependencies within your nix PER NVIM PACKAGE within the SAME CONFIG DIRECTORY and have your lua know about it without any stress (thanks to the nixCats messaging system).

The name is NIX CATEGORIES but shorter. 🐱

You can use it to have as many neovim configs as you want. For direnv shells and stuff.

But its also just a normal neovim configuration installed via nix with an easy way to pass info from nix to lua so use it however you want.

Simply add plugins and lsps and stuff to lists in flake.nix, and then configure like normal!

You dont always want a plugin? Ask `nixCats("the.category")` and learn if you want to load it this time!

Want to pass info from nix to lua? Just add it to the same table in nix and then `nixCats("some.info")`.

You will not be backed into any corners using the nixCats scheme, either as a flake or module.

Except 2.

1. The module template cannot be ran via nix run. The 3rd template, which is just the output function of the flake template in a default.nix file, can solve that easily if desired later when working on your nix configuration.
2. The section below marked [attention](#attention)

It is easy to convert between flake and module versions, so do not worry at the start which one to choose, all options will be available to you in both, including installing multiple versions of neovim to your PATH.

However the flake can be used without nixos or home manager, so if you don't have that set up or aren't on nixos, you should choose the flake to start with.

I wrote the [nix](./nix) directory so you dont have to. It contains the builder and utils and help and templates and can be imported straight from github via the utils set, allowing you to keep your directory for your configuration. The help is imported within the builder and thus will be available in any configuration based on nixCats.

Everything you need to make a config based on nixCats is exported by the nixCats.utils variable, the templates demonstrate usage of it and make it easy to start.

#### *The reasons I wanted to do it this way:*

- The setup instructions for new plugins are all in Lua so translating them is effort.
- I didn't want to be forced into creating a new lua file, 
    writing lua within nix, or creating hooks for a DSL for every new plugin
    in order to export options to nix or pass info from nix if desired.
- I wanted my neovim config to be neovim flavored 
    (so that I can take advantage of all the neovim dev tools with minimal fuss)
- I wanted to be able to opt into having multiple configs in 1 directory at any time if desired.
- I wanted to be able to run it via nix run from anywhere with nix, and add it to project shells with a couple of lines.

So nixCats is a wrapper for neovim-unwrapped to allow those things which is simple to use even with complex configurations, and most of the complexity you CAN achieve is on an opt-in basis and requires little deviation.

It is designed to give you package specific config, AND nixOS integration AND home manager integration, without ditching your lua. Or even leaving lua much at all.

## Attention: <a name="attention"></a>
> You cannot launch nixCats with the nvim command. You may, however, launch it with anything else you would like to choose.

> This is a side effect of being able to install multiple simultaneous versions of the same version of nvim to the same user's PATH via a module such as home manager, something that would normally cause a collision error.

> The default launch name is the package name in the packageDefinitions set in flake.nix for that package. You may then make any other aliases that you please as long as they do not conflict.

> This also means that your $EDITOR variable should match the name in your packageDefinitions set in flake.nix so that stuff like git opens the right thing.

> Nvim does not know about the wrapper script. Nvim is named `nvim` and is in a file in the store. It is still at `<store_path>/bin/nvim` and is aware of that. Thus, this should not cause any other issues beyond the way nvim is normally wrapped via the wrappers in nixpkgs.

> Because it is still at `<store_path>/bin/nvim`, you also may only have 1 version of neovim itself per user. This particular requirement however might be possible to fix because this version is not in your PATH, the wrappers are. I am honestly unsure why this is not possible, but it wasn't solved by nixpkgs either and hasn't been an issue.

## Table of Contents
1. [Features](#features)
2. [Introduction](#introduction)
3. [Installation](#installation)
4. [Further Usage](#extrainfo)
5. [Extra Information](#outro)
6. [Alternative / Similar Projects](#alternatives)

## Features: <a name="features"></a>
- Allows normal neovim configuration file scheme to be loaded from the nix store.
- Configure without leaving flake.nix and regular neovim config scheme and still export advanced configuration options!
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
  - If using a flake it can then be imported by someone else and reconfigured and exported again. And again. And again. You get it.
- blank flake template that can be initialized into your existing neovim config directory
- blank module template that can be initialized into your existing neovim config directory and moved to a home/system configuration
- `luaUtils` template containing the tools for integrating with pckr or lazy.
- other templates containing examples of how to do other things with nixCats, and even one that implements the main init.lua of kickstart.nvim! (for a full list see [:help nixCats.templates](./nix/nixCatsHelp/installation.txt))
- Extensive in-editor help.
- I mentioned the templates already but if you want to see them all on github they are here: [templates](./nix/templates)

## Introduction <a name="introduction"></a>

This is a kickstarter style repo. It borrows a LOT of lua from [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim). It has mostly the same plugins.

This repo is not a lua showcase. You are meant to use your own lua once you understand what is going on.

For 95% of plugins and lsps, you won't need to do more than add plugin names to categories you make in flake.nix,
then configure in lua using lspconfig or the regular setup or config functions provided by the plugin.

It also allows for easy project specific packaging using nixCats for all the cool direnv stuff.

You can `nixCats('attr.path.to.value')` to discover what nix categories you created are included in the current package.

Doing so allows you to define as many different packages as you want from the same config file.

nixCats can also send other info from nix to lua other than what categories are included, but that is the main use.

It then also exports as much stuff as possible based on how you configured your category and package definitions, including home manager and nixos modules.

You should make use of the in-editor help at:

[:help nixCats](./nix/nixCatsHelp/nixCats.txt)

[:help nixCats.flake](./nix/nixCatsHelp/nixCatsFlake.txt)

The help can be viewed here on github but it is adviseable to use a nix shell to view it from within the editor.

Simply run `nix shell github:BirdeeHub/nixCats-nvim` and then run `nixCats` to open nvim and read it.

Or `nix run github:BirdeeHub/nixCats-nvim` to open it directly.

This is because there is (reasonable) syntax highlighting for the code examples in the help when viewed within nvim.

There is about as much help as there is nix code in this entire project.

> An important note: if you add a file,
> nix will not package it unless you add it 
> to your git staging before you build it...
> So nvim wont be able to find it...
> So, run git add before you build,
> especially when using the wrapRc option.

Again, the lua is just [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim), with a couple changes. 

It works as a regular config folder without any nix too using the `luaUtils` template and [help: nixCats.luaUtils](./nix/nixCatsHelp/luaUtils.txt).

`luaUtils` contains the tools and advice to adapt your favorite package managers to give your nix setup the ultimate flexibility from before of trying to download all 4 versions of rust, node, ripgrep, and fd for your overcomplicated config on a machine without using nix...

In terms of the nix code, you should not have to leave your template's equivalent of [flake.nix](./flake.nix) except OCCASIONALLY [customBuildsOverlay](./overlays/customBuildsOverlay.nix) when the thing you wish to install is not on nixpkgs and the standardPluginOverlay does not work.

All config folders like `ftplugin/` and `after/` work as designed (see `:h rtp`), if you want lazy loading put it in `optionalPlugins` in a category in the flake and call `vim.cmd('packadd <pluginName>')` from an autocommand or keybind when you want it.

It runs on linux, mac, and WSL.

You will need nix with flakes enabled, git, a clipboard manager of some kind, and a terminal that supports bracketed paste. If you're not on linux you don't need to care what those last 2 things mean. You also might want a [nerd font](https://www.nerdfonts.com/) for some icons depending on your OS and configuration.


---

#### Installation: <a name="installation"></a>
see :help [nixCats.installation_options](./nix/nixCatsHelp/installation.txt)
for more info, including a list of templates available.

```bash
# to test:
nix shell github:BirdeeHub/nixCats-nvim
#or
nix shell github:BirdeeHub/nixCats-nvim#nixCats
# If using zsh with extra regexing, be sure to escape the #
```
Now, typing `nixCats` will open nixCats until you exit the shell.

Now that you are within an editor outfitted to edit a flake,
you can access the help for nixCats by typing `:help nixCats` and choosing one
of the options suggested by the auto-complete.

Now that you have access to the help and a nix lsp, to get started,
first exit neovim. (but not the nix shell!)

In a terminal, navigate to your nvim directory and run the following command:
```bash
  # Choose one of the following 3:
  # flake template:
  nix flake init -t github:BirdeeHub/nixCats-nvim
  # module template:
  nix flake init -t github:BirdeeHub/nixCats-nvim#module
  # the outputs function of the flake template but as its own file
  # callable with import ./the/dir { inherit inputs; }
  # to recieve all normal flake outputs
  nix flake init -t github:BirdeeHub/nixCats-nvim#nixExpressionFlakeOutputs

  # for package manager integration utilities for functionality without nix
  # added at lua/nixCatsUtils also run:
  nix flake init -t github:BirdeeHub/nixCats-nvim#luaUtils

  # If using zsh with extra regexing, be sure to escape the #
```
This will create an empty version of flake.nix (or systemCat.nix and homeCat.nix) for you to fill in,
along with an empty overlays directory for any custom builds from source
required, if any. It will directly import the utils and thus also the builder and
help from nixCats-nvim itself, keeping your configuration clean.

Re-enter the nixCats nvim version by typing `nixCats .` and take a look!
Reference the help and nixCats-nvim itself as a guide for importing your setup.
Typing `:help nixCats` will open up a list of help options for this flake via auto-complete.

You add plugins to the flake.nix, call whatever setup function is required by the plugin,
and use lspconfig to set up lsps. You may optionally choose to set up a plugin
only when that particular category is enabled in the current package by checking `nixCats('your.cats.name')` first.

It is a similar process to migrating to a new neovim plugin manager.

Use a template, (or clone or fork the repo if you want)
and migrate your plugins into the flake.nix file provided.

Then configure in lua.

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

#### Further usage: <a name="extrainfo"></a>

(full usage covered in included help files, accessible here and inside neovim, but *much better viewed in-editor*)

You may need to add their link to the flake inputs if they are not on nixpkgs already.

For specific tags or branches look at [this nix documentation](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#examples) and use that format in your flake input for it.

It is made to be customized into your own portable nix neovim distribution 
with as many options as you wish, while requiring you to leave the normal
nvim configuration scheme as little as possible.

Think of it like, a build-your-own nixVim kit that doesn't
require you to know all about nix right away to get most of the benefits.

Further info for getting started:
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

---

### Extra Information: <a name="outro"></a>

#### Drawbacks:

Specific to my project:

You cannot launch nvim with nvim and must choose an alias.
This is the trade off for installing multiple versions of nvim to the same user's PATH from a module, something that would normally cause a collision error.

General nix + nvim things:

Some vscode debuggers are not on nixpkgs so you have to build them in customBuildsOverlay. 
Let me know when you figure it out I'm kinda a noob still. [How to contribute](./CONTRIBUTING.md)
Mason does not work on nixOS although it does on other OS options.

#### Special mentions:

Many thanks to Quoteme for a great repo to teach me the basics of nix!!! I borrowed some code from it as well because I couldn't have written it better yet.

[./nix/utils/standardPluginOverlay.nix](./nix/utils/standardPluginOverlay.nix) is copy-pasted from [a section of Quoteme's repo.](https://github.com/Quoteme/neovim-flake/blob/34c47498114f43c243047bce680a9df66abfab18/flake.nix#L42C8-L42C8)

Thank you!!! It taught me both about an overlay's existence and how it works.

I also borrowed a decent amount of code from nixpkgs and made modifications.

### Alternative / similar projects: <a name="alternatives"></a>

- [`kickstart.nvim`](https://github.com/nvim-lua/kickstart.nvim):
  This project was the start of my neovim journey and I would 100% suggest it over this one to anyone new to neovim.
  It does not use Nix to manage plugins. Use nixCats after this one if you want to move your version of kickstart to nix.
- [`kickstart-nix.nvim`](https://github.com/mrcjkb/kickstart-nix.nvim):
  A project that, like this one, also holds to a normal neovim config structure.
  It starts you at the basics, using the raw, wrapNeovimUnstable function with no modifications.
   - If the category/messaging system of nixCats isn't for you, this is probably your next best starting point.
- [`NixVim`](https://github.com/nix-community/nixvim):
  A Neovim distribution configured using a NixOS module.
  Much more comparable to a neovim distribution like lazyVim or astrovim and the like, configuration entirely in nix.
- [`Luca's super simple`](https://github.com/Quoteme/neovim-flake):
  Definitely the simplest example I have seen thus far. I took it and ran with it, read a LOT of docs and nixpkgs source code and then made this.
  I mentioned it above in the special mentions. As someone with no exposure to functional programming, such a simple example was absolutely fantastic.
- [`neovim-flake`](https://github.com/jordanisaacs/neovim-flake):
  Configured using a Nix module DSL.
