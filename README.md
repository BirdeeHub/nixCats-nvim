# nixCats-nvim: A Lua-natic's kickstarter flake

This is a kickstarter style repo. It borrows a LOT of lua from [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim). It has mostly the same plugins.

This repo is not a lua showcase. You are meant to use your own lua once you understand what is going on.

It is aimed at people who know enough lua to comfortably proceed from a kickstarter level setup
who want to swap to using nix while still using lua for configuration.

For 95% of plugins and lsps, you won't need to do more than add plugin names to lists you make in flake.nix,

then configure in lua using lspconfig or the regular setup or config functions provided by the plugin.

The end result is it ends up being very much like using a neovim package manager,

except with the bonus of being able to install and set up more than just neovim plugins.

It also allows for project specific packaging using nixCats for all the cool direnv stuff.

You can require('nixCats') for what nix categories you created are included in the current package.

The categories are the lists you created that you added plugins to.

Doing so allows you to define as many different packages as you want from the same config file.

nixCats can also send other info from nix to lua other than what categories are included, but that is the main use.

It then also exports as much stuff as possible for when you want to add some version of your own nixCats flake 
to a system nix config flake but maybe want to change something for that specific system without making a separate package for it if desired.

You should make use of the in-editor help at:

[:help nixCats](./nixCatsHelp/nixCats.txt)

[:help nixCats.flake](./nixCatsHelp/nixCatsFlake.txt)

The help can be viewed here on github but it is adviseable to use a nix shell to view it from within the editor.

Simply run ```nix shell github:BirdeeHub/nixCats-nvim``` and run nvim to read it.

This is because there is (reasonable) syntax highlighting for the code examples in the help when viewed within nvim.

There is about as much help as there is nix code in this entire project.

    An important note: if you add a file,
    nix will not package it unless you add it 
    to your git staging before you build it...
    So nvim wont be able to find it...
    So, run git add before you build,
    especially when using the wrapRc option.

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
```

#### These are the reasons I wanted to do it this way: 

    The setup instructions for new plugins are all in Lua so translating them is effort.
        I don't even want to translate instructions 
        into lazy or packer or the others, let alone nix.

    I didn't want to be forced into creating a new lua file, 
        writing lua within nix, or creating hooks for a DSL for every new plugin.

    I wanted my neovim config to be neovim flavored 
        (so that I can take advantage of all the neovim dev tools with minimal fuss)

    I still wanted my config to know what plugins and LSPs I included in the package
        so I created nixCats.

In terms of the nix code, you should not have to leave [flake.nix](./flake.nix) or occasionally [customBuildsOverlay](./overlays/customBuildsOverlay.nix).

That being said, if only for better understanding, there is a guide to going outside of those 2 files in [:help nixCats.flake.nixperts.nvimBuilder](./nixCatsHelp/nvimBuilder.txt) in case you want to.

All config folders like ftplugin and after work as designed (see :h rtp), if you want lazy loading put it in optionalPlugins in a category in the flake and call packadd when you want it.
Although, it does specifically expect init.lua rather than init.vim at root level.

It runs on linux, mac, and WSL. 
You will need nix with flakes enabled, git, a clipboard manager of some kind, and a terminal that supports bracketed paste. If you're not on linux you don't need to care what those last 2 things mean.

You can delete the lua and copy paste your lua into this flake, and then swap your package manager, and then define any package specific stuff you want.

This is opposed to the usual method of cloning the flake, then put your lua stuff into where the flake says, possibly requiring it to be in the spots it has defined to be packaged in certain circumstances.

This is designed to give you package specific config, AND nixOS integration, without ditching your lua.

That being said, definitely explore first while you understand the concept. It boils down to a few concepts.

In there are 2 general ideas I used to create this, stated above, and then a bunch of category sorting. The rest are just natural extensions of that.

    The idea:
    1. import flake as config file.
    2. Sort categories.
    3. Convert set that chooses the categories included verbatim to a lua table returned by nixCats.

    The clever part is organizing it so that doesn't suck. 
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

You can optionally ask what categories you have in this package, whenever you require nixCats

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
```

However, you should really just clone or fork the repo.

It is made to be customized into your own portable nix neovim distribution with as many options as you wish.

If you use the regularCats package, you only need to edit the flake itself to install new things.

This is useful for faster iteration while editing lua config, as you then only have to restart it rather than rebuild.

However that also means the regularCats package must be cloned locally.

You should clone regularCats to your ~/.config/ directory
and make sure the filename is ```nixCats-nvim``` so that you can still keep everything in the same place when you do this.

To change this name, you can to change configDirName in the settings section of flake.nix, or the name of the directory. 
This also affects .local and the like.

If you want to add it to another flake, there are many methods. Here is an illustration of a few.

You could run nix build on a directory containing only the following as a flake.nix

outside of having separate packages in one configuration,
The other option shown is your main form of options you create.

That being, the ablity to choose which categories you wish to include from within another flake.

You can make the categories however you wish when you 
add plugins to flake.nix and/or require('nixCats') in your lua and retrieve the value.

```nix
{
    description = "How to import nixCats flake in a flake. Several ways.";
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
        flake-utils.url = "github:numtide/flake-utils";
        nixCats-nvim.url = "github:BirdeeHub/nixCats-nvim";
    };
    outputs = { self, nixpkgs, flake-utils, nixCats-nvim }@inputs: 
    flake-utils.lib.eachDefaultSystem (system: let 
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            # Importing via overlay makes them accessible
            # via pkgs.packageName
            nixCats-nvim.overlays.${system}.nixCats
            nixCats-nvim.overlays.${system}.regularCats
          ];
        };
        # this is the equivalent of the nixCats package
        # except we can set the categories in the flake that calls it.
        customVimBuilder = nixCats-nvim.customPackager.${system} packageDefinitions;
        packageDefinitions = {
          customvim = {
            settings = {
              wrapRc = true;
              configDirName = "nixCats-nvim";
              viAlias = false;
              vimAlias = true;
            };
            categories = {
              generalBuildInputs = true;
              markdown = true;
              gitPlugins = true;
              general = true;
              custom = true;
              neonixdev = true;
              test = true;
              debug = false;
              # this does not have an associated category of plugins, 
              # but lua can still check for it
              lspDebugMode = false;
              themer = true;
              # you could also pass something else:
              colorscheme = "onedark";
              # you could :lua print(vim.inspect(require('nixCats')))
              # I got carried away and it worked FIRST TRY.
              # see :help nixCats
            };
          };
        };
    in
        {
            packages.default = nixCats-nvim.packages.${system}.nixCats;
            packages.nixCats = pkgs.nixCats;
            packages.regularCats = pkgs.regularCats;
            packages.customvim = customVimBuilder "customvim";
        }
    );
}
```
There are many more methods not covered in this readme, but are covered in the included help files.
see: [nixCats.installation_options](./nixCatsHelp/installation.txt)

With them you could partially or entirely add to, change, or recreate this flake.nix and/or the lua 

in another flake without having to redefine things (although you can only either add new lua or recreate it).

---

#### Special mentions:

Many thanks to Quoteme for a great repo to teach me the basics of nix!!! I borrowed some code from it as well because I couldn't have written it better yet.

[./builder/standardPluginOverlay.nix](./builder/standardPluginOverlay.nix) is copy-pasted from [a section of Quoteme's repo.](https://github.com/Quoteme/neovim-flake/blob/34c47498114f43c243047bce680a9df66abfab18/flake.nix#L42C8-L42C8)

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
  A project with a similar philosophy to this one, but it has some devShell stuff for autodownloading stuff from git only within dev shell, and it does not have a category system or after folder.
- [`Luca's super simple`](https://github.com/Quoteme/neovim-flake):
  Definitely the simplest example I have seen thus far. I took it and ran with it, read a LOT of docs and nixpkgs source code and then made this.
  I mentioned it above in the special mentions. As someone with no exposure to functional programming, such a simple example was absolutely fantastic.
