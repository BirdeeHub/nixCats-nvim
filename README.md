# nixCats-nvim: for the Lua-natic's neovim config on nix!

This is a neovim configuration scheme for people who use neovim on nix and want it to be neovim flavored, but with sugar.

It is for new and advanced nix users alike, and you will find all the normal options here and then some.

Nix is for downloading. Lua is for configuring. To pass info from nix to lua, you must `''${interpolate a string}'';` So you need to write some lua in nix.

*Or do you?* Why not just make a wrapper that gives an easy way to give neovim everything it could possibly want to have and know?

Also I should be able to split it up however I want with a short `if` statement to export multiple configurations from the same directory for dev shells without duplication.
And then maybe reconfigure them again.

It should definitely be runnable via nix run and also maybe I want to load it without any nix at all when I'm feeling spicy or keep using lazy.nvim?

Also I just wanna add stuff to lists please, home.packages is so nice. Keep it simple.

The neovim config here (everything outside of [./nix](./nix)) is an example of how to use nixCats for yourself.

When you are ready, start [with](./nix/templates/nixExpressionFlakeOutputs) a [template](./nix/templates/fresh) [and](./nix/templates/module) include your normal configuration, and refer back [here](./flake.nix) [or](./init.lua) to the [help](./nix/nixCatsHelp) for guidance!
If you use lazy, consider using the lazy.nvim wrapper [in luaUtils](./nix/templates/luaUtils/lua/nixCatsUtils) documented in [:h luaUtils](./nix/nixCatsHelp/luaUtils.txt) and [demonstrated here.](./nix/templates/kickstart-nvim)

##### (just remember to change your $EDITOR variable, the reason why is explained below in the section marked [Attention](#attention))

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
- Configure all downloads without leaving `flake.nix`, use a regular neovim config scheme, and still export advanced configuration options!
- Easy-to-use Nix Category system for many configurations in 1 repository!
  - to use:
    - Make a new list in the set in the flake for it (i.e. if its a plugin you want to load on startup, put it in startupPlugins in categoryDefinitions)
    - enable the category for a particular neovim package in packageDefinitions set.
    - check for it in your neovim lua configuration with nixCats('attr.path.to.yourList')
- the nixCats command is your method of communicating with neovim from nix outside of installing plugins.
  - you can pass any extra info through the same set you define which categories you want to include.
  - it will be printed verbatim to a table in a lua file.
  - Not only will it be easily accessible anywhere from within neovim via the nixCats command, but also from your category definitions within nix as well for even more subcategory control. 
- Can be configured as a flake, in another flake, or as a nixos or home-manager module.
  - If using it as a flake or within a flake it can then be imported by someone else and reconfigured and exported again, just like the example config here.
- blank flake template that can be initialized into your existing neovim config directory
- blank module template that can be initialized into your existing neovim config directory and moved to a home/system configuration
- blank template that is called as a nix expression from any other flake. It is simply the outputs function of the flake template but as its own file, callable with your system's flake inputs.
- `luaUtils` template containing the tools for detecting if nix loaded your config or not, and integrating with lazy or other plugin managers.
- other templates containing examples of how to do other things with nixCats, and even one that implements an old version of kickstart.nvim! (for a full list see [:help nixCats.templates](./nix/nixCatsHelp/installation.txt))
- Extensive in-editor help.
- I mentioned the templates already but if you want to see them all on github they are here: [templates](./nix/templates)

## Introduction <a name="introduction"></a>

This project is a heavily modified version of the wrapNeovim/wrapNeovimUnstable functions provided by nixpkgs, to allow you to get right into a working and full-featured, nix-integrated setup based on your old configuration as quickly as possible without making sacrifices in your nix that you will need to refactor out later.

All loading can be done from [flake.nix](./flake.nix), with the option of custom overlays for specifc things there should you need it (rare!). Alternatively, you could import it as a module (nixos and/or home-manager)! It works the same way with either method. Then configure in the normal neovim scheme.

The first main feature is the nixCats messaging system, which means you will not need to write ANY lua within your nix files (although you still can), and thus can use all the neovim tools like lazydev that make configuring it so wonderful when configuring in your normal ~/.config/nvim

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

Except 1. The section above marked [attention](#attention)

It is easy to convert between all 3 starter templates, so do not worry at the start which one to choose, all options will be available to you in both,
including installing multiple versions of neovim to your PATH.

However I suggest starting with the flake standalone and then using the nixExpressionFlakeOutputs template to combine your neovim into your normal system flake.

This is because the flake standalone is easy to have in its own directory somewhere to test things out, runs without nixos or home manager,
and then the nixExpressionFlakeOutputs is literally just the outputs function, and you move your inputs to your system inputs. Then you call it.

It allows you to export everything this repo does, but with your config as the base.

The modules can optionally inherit category definitions from the flake you import from. This makes it easy to modify an existing machine if a separate nixos config is required. However they can only install and export the finished packages.

The category scheme allows you to output many different packages with different subsets of your config.

You need a minimal python3 nvim ide in a shell, and it was a subset of your previous config? Throw some `nixCats("the.category")` at it, and enable only those in a new entry in packageDefinitions.

Want one that actually reflects lua changes without rebuilding for testing? Have 2 of the same `packageDefinitions` with the same categories, except one has wrapRc = false and unwrappedCfgDir set!

I wrote the [nix](./nix) directory so you dont have to. It contains the builder and utils and help and templates and can be imported straight from github via the utils set, allowing you to keep your directory for your configuration. The help is imported within the builder and thus will be available in any configuration based on nixCats.

Everything you need to make a config based on nixCats is exported by the nixCats.utils variable, the templates demonstrate usage of it and make it easy to start.

For 95% of plugins and lsps, you won't need to do more than add plugin names to categories you make in flake.nix,
then configure in lua using lspconfig or the regular setup or config functions provided by the plugin.

You should make use of the in-editor help at:

[:help nixCats](./nix/nixCatsHelp/nixCats.txt)

[:help nixCats.flake](./nix/nixCatsHelp/nixCatsFlake.txt)

[:help nixCats.*](./nix/nixCatsHelp)

The help can be viewed here directly but it is adviseable to use a nix shell to view it from within the editor.

Simply run `nix shell github:BirdeeHub/nixCats-nvim` and then run `nixCats` to open nvim and read it.

Or `nix run github:BirdeeHub/nixCats-nvim` to open it directly and type [:h nixCats](./nix/nixCatsHelp) without hitting enter to see the help options in the auto-complete.

This is because there is (reasonable) syntax highlighting for the code examples in the help when viewed within nvim.

> An important note: if you add a file,
> nix will not package it unless you add it 
> to your git staging before you build it...
> So nvim wont be able to find it...
> So, run git add before you build.

It works as a regular config folder without any nix too using the `luaUtils` template and [help: nixCats.luaUtils](./nix/nixCatsHelp/luaUtils.txt).

`luaUtils` contains the tools and advice to adapt your favorite package managers to give your nix setup the ultimate flexibility from before of trying to download all 4 versions of rust, node, ripgrep, and fd for your overcomplicated config on a machine without using nix...

In terms of the nix code, you should not have to leave your template's equivalent of [flake.nix](./flake.nix) except OCCASIONALLY [customBuildsOverlay](./overlays/customBuildsOverlay.nix) when the thing you wish to install is not on nixpkgs and the standardPluginOverlay does not work.

All config folders like `ftplugin/`, `pack/` and `after/` work as designed (see `:h rtp`), if you want lazy loading put it in `optionalPlugins` in a category in the flake and call `vim.cmd('packadd <pluginName>')` from an autocommand or keybind when you want it. (NOTE: `packadd` does not source `after` dirs, so to lazy load those you must source those yourself (or use the lazy.nvim wrapper in [luaUtils](./nix/nixCatsHelp/luaUtils.txt))

It runs on linux, mac, and WSL. You will need nix with flakes enabled, git, a clipboard manager of some kind, and a terminal that supports bracketed paste.
If you're not on linux you don't need to care what those last 2 things mean.
You also might want a [nerd font](https://www.nerdfonts.com/) for some icons depending on your OS, terminal, and configuration.


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

Use a template and put the plugin names into the flake.nix or default.nix file provided.

You can import them from nixpkgs or straight from your inputs via a convenience overlay [:h nixCats.flake.inputs](./nix/nixCatsHelp/nixCatsFlake.txt)

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

Further info for getting started:
see :help [nixCats.installation_options](./nix/nixCatsHelp/installation.txt)

All info I could manage to cover is covered in the included help files.
For this section,
see :help [nixCats.installation_options](./nix/nixCatsHelp/installation.txt)
and also :help [nixCats.flake.outputs.exports](./nix/nixCatsHelp/nixCatsFlake.txt)

---

### Extra Information: <a name="outro"></a>

#### Drawbacks:

Specific to this project:

You cannot launch nvim with nvim and must choose an alias.
This is the trade off for installing multiple versions of nvim to the same user's PATH from a module, something that would normally cause a collision error.

General nix + nvim things:

Some vscode debuggers are not on nixpkgs so you have to build them (there's a place for it in customBuildsOverlay). 
Let people know when you figure one out or submit it to nixpkgs.

[Mason](https://github.com/williamboman/mason.nvim) does not work on nixOS although it does on other OS options. However you can make it work with SharedLibraries and lspsAndRuntimeDeps options if you choose to not use those fields for their intended purpose!

[Lazy.nvim](https://github.com/folke/lazy.nvim) works but unless you tell it not to reset the RTP you will lose your config directory and treesitter parsers. There is an included wrapper that you can use to do this reset correctly and also optionally stop it from downloading stuff you already downloaded via nix.

[lz.n](https://github.com/nvim-neorocks/lz.n) exists and due to it working within the normal neovim plugin management scheme is better suited for nix based configurations.

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
  If nixCats feels like it is too far from the metal for you and you want to build from the ground up, this is the way to go.
- [`NixVim`](https://github.com/nix-community/nixvim):
  A Neovim module scheme semi-comparable to home manager for neovim.
  They try to have a module for as many packages as they can and do a great job,
  but you can always fall back to the programs.neovim syntax if something is missing.
- [`Luca's super simple`](https://github.com/Quoteme/neovim-flake):
  Definitely the simplest example I have seen thus far. I took it and ran with it, read a LOT of docs and nixpkgs source code and then made this.
  I mentioned it above in the special mentions. As someone with no exposure to functional programming, such a simple example was absolutely fantastic.
