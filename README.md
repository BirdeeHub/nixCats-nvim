# nixCats-nvim: A Lua-natic's kickstarter flake

This is a kickstarter style repo. It borrows a LOT of lua from [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim). It has mostly the same plugins.

The lua is not all 1 file. The reason for that is personal preference. It is short enough that it could be.

It is aimed at people who know enough lua to comfortably proceed from a kickstarter level setup
who want to swap to using nix while still using lua for configuration.

For 95% of plugins, you wont need to do more than add plugins to lists,

then configure in lua using the regular setup or config functions provided by the plugin.

The end result is it ends up being very much like using a neovim package manager,

except with the bonus of being able to install and set up more than just neovim plugins.

It allows for project specific packaging using nixCats.

Simply require nixCats in your lua and it will tell you what categories you have in this package.

You should make use of the in-editor help at:

[:help nixCats](./nixCatsHelp/nixCats.txt)

[:help nixCats.flake](./nixCatsHelp/nixCatsFlake.txt)

The help can be viewed here on github but it is adviseable to use a nix shell to view it from within the editor.

This is because there is syntax highlighting for the code examples in the help when viewed within nvim.

    An important note: if you add a lua file,
    nix will not package it unless you add it 
    to your git staging before you build it...
    So nvim wont be able to find it...
    So, run git add before you build when using the wrapRc option.

#### Introduction:
 
I originally made this for myself. I wanted to swap to NixOS.

The category scheme was good. I found it easy to use.

So I implemented the whole wrapper using the scheme.

As far as I can tell it gave me all the advantages of nix, 
while having to deal with it as little as possible.

So, I posted it. Someone else liked it. 
So I fixed it up, added help, removed most of the plugins and made this.
```
The mission: 
    Replace lazy and mason with nix, keep everything else in lua. 
    Still allow project specific packaging.

The solution:
    Use nix to download the stuff and make it available to neovim.
    Include the flake itself as a plugin, allowing all config to work like normal.
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

Outside of the lua, you should not have to leave [flake.nix](./flake.nix) or occasionally [customBuildsOverlay](./overlays/customBuildsOverlay.nix).

This is because the whole wrapper has been implemented by the category system. Although there is a guide to going outside of those 2 files in [:help nixCats.flake.nixperts.nvimBuilder](./nixCatsHelp/nvimBuilder.txt) in case you want to.

All config folders like ftplugin and after work (see :h rtp), if you want lazy loading put it in optionalPlugins in a category in the flake and call packadd when you want it.

You will need nix with flakes enabled, git, a clipboard manager of some kind, and a terminal that supports bracketed paste.

It runs on linux and WSL, I have not tested it on mac but I would be surprised if it did not.

---

#### Basic usage:

(full usage covered in included help files, accessible here and inside neovim)

You install the plugins/LSP/debugger/program using nix, by adding them to a category in the flake (or creating a new category for it!)

You may need to add their link to the flake inputs if they are not on nixpkgs already.

For specific tags look at [this nix documentation](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#examples) and use that format in your flake input for it.

You then choose what categories to include in the package.

You then set them up in your lua, using the default methods to do so. No more translating to your package manager! (If you were using lazy, the opt section goes into the setup function in the lua)

You can optionally ask what categories you have in this package, whenever you require nixCats

You do not have to name your folder within the lua directory myLuaConf. Just change RCName in the flake. Doing this is documented in :help nixCats.flake.outputs.settings

If you encounter any build steps that are not well handled by nixpkgs, 
or you need to import a plugin straight from git that has a non-standard build step and no flake,
and need to do a custom definition, [customBuildsOverlay](./overlays/customBuildsOverlay.nix) is the place for it. 
Fair warning, this requires knowledge of nix derivations and should be needed only infrequently.

#### Drawbacks:

Some vscode debuggers are not on nixpkgs so you have to build them in customBuildsOverlay. 
Let me know when you figure it out I'm kinda a nix noob still. [How to contribute](./CONTRIBUTING.md)

This is a general nix thing, not specific to this project.


---

#### Installation:

```bash
# to test:
nix shell github:BirdeeHub/nixCats-nvim
#or
nix shell github:BirdeeHub/nixCats-nvim#nixCats
# If using zsh with extra regexing, be sure to escape the #
```

However, you should really just clone or fork the repo,
because to edit your config, you edit the lua in your flake. 

If you use the regularCats package, you only need to edit the flake itself to install new things.

This is useful for faster iteration while editing lua config, as you then only have to restart it rather than rebuild.

You should clone regularCats to your ~/.config/ directory and make sure the filename is ```nixCats-nvim```

If it is named something else, you will have to change configDirName in the settings section of flake.nix, or the name of the directory. 
This also affects .local and the like.

If you want to add it to another flake, choose one of these methods:

```nix
{
    description = "How to import nixCats flake in a flake. 2 ways.";
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
            nixCats-nvim.outputs.overlays.${system}.nixCats
            nixCats-nvim.outputs.overlays.${system}.regularCats
          ];
        };
    in
        {
            packages.default = nixCats-nvim.outputs.packages.${system}.nixCats;
            packages.nixCats = pkgs.nixCats;
            packages.regularCats = pkgs.regularCats;
        }
    );
}
```

Although, again, it is preferrable to just clone it, either from within nix, or outside of it.

---

#### Special mentions:

Many thanks to Quoteme for a great repo to teach me the basics of nix!!! I borrowed some code from it as well because I couldn't have written it better yet.

[standardPluginOverlay in ./overlays/default.nix](./overlays/default.nix) is copy-pasted from [a section of Quoteme's repo.](https://github.com/Quoteme/neovim-flake/blob/34c47498114f43c243047bce680a9df66abfab18/flake.nix#L42C8-L42C8)

Thank you!!! It taught me both about an overlay's existence and how it works.

I also borrowed some code from nixpkgs and included links.

#### Alternative / similar projects:

- [`kickstart.nvim`](https://github.com/nvim-lua/kickstart.nvim):
  This project was the start of my neovim journey and I would 100% suggest it over this one to anyone new to neovim.
  Does not use Nix to manage plugins. Use this one after if you want to move your version of kickstart to nix.
- [`neovim-flake`](https://github.com/jordanisaacs/neovim-flake):
  Configured using a Nix module DSL.
- [`NixVim`](https://github.com/nix-community/nixvim):
  A Neovim distribution configured using a NixOS module.
  Much more comparable to a neovim distribution like lazyVim or astrovim and the like, configuration entirely in nix.
- [`kickstart-nix.nvim`](https://github.com/mrcjkb/kickstart-nix.nvim):
  A project with a similar philosophy to this one, but does not have a category system,
  and has some devShell stuff for autodownloading stuff only within dev shell.
- [`Luca's super simple`](https://github.com/Quoteme/neovim-flake):
  Definitely the simplest example I have seen thus far. I took it and ran with it, read a LOT of docs and nixpkgs source code and then made this.
  I mentioned it above in the special mentions.
