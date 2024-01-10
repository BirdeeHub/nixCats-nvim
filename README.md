# nixCats-nvim: A Lua-natic's kickstarter flake

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
and lspconfig instead of mason (because mason doesnt work very well on nixOS and the whole point was to replace it and lazy with nix)

It also has completion for the command line because I like that and also is multi file because I want to show the folders all work and because I like that too.

When you are deleting my lua dont forget about the after folder. It makes the numbers purple. 
It does this afterwards because stuff kept overriding it and it was a good opportunity to show the utility of the after folder.

#### Introduction:
 
I originally made this just for myself. I wanted to swap to NixOS.

The category scheme was good. I found it easy to use.

As far as I can tell it gave me all the advantages of nix, 
while having to deal with it as little as possible.

```
The mission: 
    Replace lazy and mason with nix, keep everything else in lua. 
    Still allow project specific packaging.

The solution:
    Use nix to download the stuff and make it available to neovim.
    Include the flake as a config folder, allowing all config to work like normal.
    Create nixCats so the lua may know what categories are packaged
    You may optionally have your config in your normal directory as well.
        (You will still be able to reference nixCats and the help should you do this.)
        
    I ended up including a way to download via pckr because people seem to want
        a way to load their config without nix as an option.
```

#### These are the reasons I wanted to do it this way: 

    The setup instructions for new plugins are all in Lua so translating them is effort.
        instead of lazy, use pckr for emergency downloads without nix.

    I didn't want to be forced into creating a new lua file, 
        writing lua within nix, or creating hooks for a DSL for every new plugin.

    I wanted my neovim config to be neovim flavored 
        (so that I can take advantage of all the neovim dev tools with minimal fuss)

    I still wanted my config to know what plugins and LSPs I included in the package
        so I created nixCats.

In terms of the nix code, you should not have to leave [flake.nix](./flake.nix) or occasionally [customBuildsOverlay](./overlays/customBuildsOverlay.nix).

That being said, if only for better understanding, there is a guide to going outside of those 2 files in [:help nixCats.flake.nixperts.nvimBuilder](./nix/nixCatsHelp/nvimBuilder.txt) in case you want to.

All config folders like `ftplugin/` and `after/` work as designed (see :h rtp), if you want lazy loading put it in `optionalPlugins` in a category in the flake and call `packadd` when you want it.
Although, it does specifically expect `init.lua` rather than `init.vim` at root level.

It runs on linux, mac, and WSL. 
You will need nix with flakes enabled, git, a clipboard manager of some kind, and a terminal that supports bracketed paste. If you're not on linux you don't need to care what those last 2 things mean.

This is designed to give you package specific config, AND nixOS integration AND home manager integration, without ditching your lua. Or even leaving lua much at all.

That being said, definitely explore first while you understand the concept. It boils down to a few concepts.

    The idea:
    1. import flake as config file.
    2. Sort categories.
    3. Convert set that chooses the categories included verbatim to a lua table returned by nixCats.
    4. export all the options possible

    The clever part is organizing it so that it is not unusable.
    Read the nixperts help if you are curious as to how I implemented these 3 concepts,
    then check ./builder/utils.nix if you are REALLY curious.

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

#### Drawbacks:

Some vscode debuggers are not on nixpkgs so you have to build them in customBuildsOverlay. 
Let me know when you figure it out I'm kinda a nix noob still. [How to contribute](./CONTRIBUTING.md)

Mason does not work on nixOS although it does on other OS options.

These are general nix things, not specific to this project.

---

#### Installation:

```bash
# to test:
nix shell github:BirdeeHub/nixCats-nvim
#or
nix shell github:BirdeeHub/nixCats-nvim#nixCats
# If using zsh with extra regexing, be sure to escape the #

# now running nvim will open nixCats until you exit the shell.
```
Now that you are within an editor outfitted to edit a flake,
you can access the help for nixCats by typing :help nixCats and choosing one
of the options suggested by the auto-complete.

Now that you have access to the help and a nix lsp, to get started,
first exit neovim. (but not the nix shell!)

In a terminal, navigate to your nvim directory and run the following command:
```bash
  nix flake init -t github:BirdeeHub/nixCats-nvim
```
This will create an empty version of flake.nix for you to fill in,
along with an empty overlays directory for any custom builds from source
required, if any. It will directly import the builder, utils, and
help from nixCats-nvim itself, keeping your configuration clean.

Re-enter the nixCats nvim version by typing nvim . and take a look!
Reference the help and nixCats-nvim itself as a guide for importing your setup.

You add plugins to the flake.nix, call whatever setup function is required by the plugin,
and use lspconfig to set up lsps. You may optionally choose to set up a plugin
only when that particular category is enabled in the current package by checking ```nixCats('your.cats.name')``` first.

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
There are many, thanks to the virtues of the category scheme of this flake.

It is made to be customized into your own portable nix neovim distribution 
with as many options as you wish, while requiring you to leave the normal
nvim configuration scheme as little as possible.

Think of it like, a build-your-own nixVim kit that doesn't
require you to know all about nix right away to get most of the benefits.

Further info:

There are several other templates.
They are designed to be used as examples for
importing versions of your nixCats into another existing configuration.

They are not particularly suited to being ran directly in your
nvim config folder like the first one was.
They are minimal examples of how to import nixCats in different ways.

This one shows the options that get exported as a home manager module
It also shows how to import the module.
It is not a complete home manager flake in and of itself.
```bash
  nix flake init -t github:BirdeeHub/nixCats-nvim#homeModule
```
This one shows the options that get exported as a nixOS module
It also shows how to import the module.
It is not a complete nixOS flake in and of itself.
```bash
  nix flake init -t github:BirdeeHub/nixCats-nvim#nixosModule
```
This next one shows, within another flake, how to import 
only some parts of other nixCats and overwrite or add others.
You could use it, for example, to import just the overlays from another nixCats
without having to copy paste them into your own version.
```bash
  nix flake init -t github:BirdeeHub/nixCats-nvim#mergeFlakeWithExisting
```
When you make categories in your flake.nix,
and then check them in lua, that creates your primary set of options.

You can modify ANYTHING within a flake that imports your nixCats,
however, usually, all you would need to do is choose a package you defined,
or put different values in categories, because you can check the categories
set within your lua and react to them.

You could more or less build your own nixVim in your flake by choosing
your categories carefully and referring to them within your lua.
And then the options would get automatically exported
for any way a nix user may want to set them.

All info is covered in the included help files.
For this section,
see :help [nixCats.installation_options](./nix/nixCatsHelp/installation.txt)
and also :help [nixCats.flake.outputs.exports](./nix/nixCatsHelp/nixCatsFlake.txt)

With them you could partially or entirely add to, change, or recreate this flake.nix and/or the lua 
in another flake without having to redefine things (although you can only either add new lua or recreate it).

---

#### Special mentions:

Many thanks to Quoteme for a great repo to teach me the basics of nix!!! I borrowed some code from it as well because I couldn't have written it better yet.

[./builder/standardPluginOverlay.nix](./nix/utils/standardPluginOverlay.nix) is copy-pasted from [a section of Quoteme's repo.](https://github.com/Quoteme/neovim-flake/blob/34c47498114f43c243047bce680a9df66abfab18/flake.nix#L42C8-L42C8)

Thank you!!! It taught me both about an overlay's existence and how it works.

I also borrowed some code from nixpkgs and included links.

#### Alternative / similar projects:

- [`kickstart.nvim`](https://github.com/nvim-lua/kickstart.nvim):
  This project was the start of my neovim journey and I would 100% suggest it over this one to anyone new to neovim.
  It does not use Nix to manage plugins. Use nixCats after this one if you want to move your version of kickstart to nix.
- [`neovim-flake`](https://github.com/jordanisaacs/neovim-flake):
  Configured using a Nix module DSL.
- [`NixVim`](https://github.com/nix-community/nixvim):
  A Neovim distribution configured using a NixOS module.
  Much more comparable to a neovim distribution like lazyVim or astrovim and the like, configuration entirely in nix.
- [`kickstart-nix.nvim`](https://github.com/mrcjkb/kickstart-nix.nvim):
  A project with a similar philosophy to this one, but much simpler in many respects.
  It does not have an after folder, nor does it have categories, exported options, or modules.
  It does have a download system for downloading tester plugins only when ran as a dev shell.
- [`Luca's super simple`](https://github.com/Quoteme/neovim-flake):
  Definitely the simplest example I have seen thus far. I took it and ran with it, read a LOT of docs and nixpkgs source code and then made this.
  I mentioned it above in the special mentions. As someone with no exposure to functional programming, such a simple example was absolutely fantastic.
