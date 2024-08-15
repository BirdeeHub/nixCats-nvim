# nixCats-nvim: for the Lua-natic's neovim config on nix!

This is a neovim configuration scheme for new and advanced nix users alike, and you will find all the normal options here and then some.

Nix is for downloading. Lua is for configuring. To pass info from nix to lua, you must `''${interpolate a string}'';` So you need to write some lua in strings in nix.

*Or do you?* Not anymore you don't! In fact, you barely have to write any nix at all. Just put stuff in the lists provided, and configure normally.

If you like the normal neovim configuration scheme, but want your config to be runnable via `nix run` and have an easier time dealing with dependency issues, this repo is for you.

Even if you dont use it for downloading plugins at all, preferring to use lazy and mason and deal with issues as they arise, this scheme will have useful things for you.

It allows you to provide a configuration and any dependency you could need to your neovim in a contained and reproducible way,
buildable separately from your nixos or home-manager config.

It allows you to easily pass arbitrary information from nix to lua, easily reference things installed via nix, and even output multiple neovim packages with different subsets of your configuration without duplication, import and override and re-export your nvim config in dev shells, etc...

The example neovim config here ([everything](https://github.com/BirdeeHub/nixCats-nvim) outside of the internals at [./nix](https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix)) is just one example of how to use nixCats for yourself.
Everything in [./nix/templates](https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix/templates) is also either a starter template, or more examples.
The [in-editor help](https://nixcats.org/TOC.html) will be available in any nvim that uses the nixCats builder, and is best viewed there, where the vimdoc links work.
There is significantly more help and example in this repository than there is actual functional code for the nixCats wrapper.

When you are ready, start [with](https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix/templates/nixExpressionFlakeOutputs) a [template](https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix/templates/fresh) and include your normal configuration, and refer back here or to the in-editor help or the other templates for guidance!

If you use lazy,nvim, consider using the lazy.nvim wrapper [in luaUtils template](https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix/templates/luaUtils/lua/nixCatsUtils) documented in [:h luaUtils](https://nixcats.org/nixCats_luaUtils.html) and [demonstrated here](https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix/templates/kickstart-nvim). The luaUtils template also contains other simple tools that will help if you want your configuration to still load without nix involved in any way.

##### (just remember to change your $EDITOR variable if you named your package something other than nvim!)

## Attention: <a name="attention"></a>
> You may launch your neovim built via nixCats with any name you would like to choose.

> The default launch name is the package name in the packageDefinitions set in flake.nix for that package. You may then make any other aliases that you please as long as they do not conflict.

> This means that your $EDITOR variable should match the name in your packageDefinitions set in flake.nix so that stuff like git opens the right thing, because that is what the desktop file is called.

> If your aliases conflict and you try to install them both to your path via home.packages or environment.systemPackages, it will throw a collision error.

> Nvim does not know about the wrapper script. It is still at `<store_path>/bin/nvim` and is aware of that. Thus, this should not cause any issues beyond the way nvim is normally wrapped via the wrappers in nixpkgs.

## Table of Contents
1. [Features](#features)
2. [Installation](#installation)
3. [Introduction](#introduction)
5. [Extra Information](#outro)
6. [Alternative / Similar Projects](#alternatives)

## Features: <a name="features"></a>
- Allows normal neovim configuration file scheme to be loaded from the nix store.
- Configure all downloads from a single nix file, use a regular neovim config scheme with full visibility of your nix!
- Easy-to-use Nix Category system for many configurations in 1 repository!
  - to use:
    - Make a new list in the set in the flake for it (i.e. if its a plugin you want to load on startup, put it in startupPlugins in categoryDefinitions)
    - enable the category for a particular neovim package in packageDefinitions set.
    - check for it in your neovim lua configuration with nixCats('attr.path.to.yourList')
- the [nixCats command](https://nixcats.org/nixCats_plugin.html) is your method of communicating with neovim from nix outside of installing plugins.
  - you can pass any extra info through the same set you define which categories you want to include.
  - it will be printed verbatim to a table in a lua file.
  - Not only will it be easily accessible anywhere from within neovim via the nixCats command, but also from your category definitions within nix as well for even more subcategory control. 
- Can be configured as a:
  - flake
  - in another flake
  - as a nixos or home-manager module
  - entirely via calling the override function on a nixCats based package.
  - It can then be imported and reconfigured without duplication and exported again. And again. and again.
- blank flake [template](https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix/templates/fresh) that can be initialized into your existing neovim config directory to get you started!
  - because you can mess around with it in its own repo in any directory, this is the lowest barrier of entry, and transitions well into any other template if desired.
- blank [template](https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix/templates/nixExpressionFlakeOutputs) that is called as a nix expression from any other flake.
  - It is simply the outputs function of the flake template above but as its own file, callable with your system's flake inputs, and returning all the normal flake outputs the other would have.
  - great for integrating into a system config and still being able to output the finished packages from your system flake.
- blank override [template](https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix/templates/overwrite) that achieves functionality the same as the above two, but entirely via using the override function on the example nvim package from the nixCats flake.
- blank module [template](https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix/templates/module) that exports the configuration of your packages in module form, inherits values from your other template and can be reconfigured. Similar to override, but as a module.
- luaUtils [template](https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix/templates/luaUtils) template containing the tools for detecting if nix loaded your config or not, and integrating with lazy.nvim or other plugin managers.
  - this is an optional, additional template.
  - proper useage of this template can yield a configuration that you can use both with or without nix.
  - contains the lazy.nvim wrapper.
- other templates containing examples of how to do other things with nixCats, and even one that implements the entirety of [kickstart.nvim](https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix/templates/kickstart-nvim) using the lazy wrapper! (for a full list see [:help nixCats.templates](https://nixcats.org/nixCats_installation.html))
- ability to call override as many times as you like to fully recustomize or combine packages
- [Extensive in-editor help.](https://nixcats.org/TOC.html)
- I mentioned the templates already but if you want to see them all on github they are here: [templates](https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix/templates)

---

#### Installation: <a name="installation"></a>
see :help [nixCats.installation_options](https://nixcats.org/nixCats_installation.html)
for more info, including a list of templates available (as well as a 100 line overview of what nixCats is and how to use it)

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

In a terminal, navigate to your nvim directory and
run your choice of the following commands (don't worry! It doesnt overwrite):
```bash
  # Choose one of the following to run at the top level of your neovim config:
  # flake template:
  nix flake init -t github:BirdeeHub/nixCats-nvim
  # the outputs function of the flake template but as its own file
  # callable with import ./the/dir { inherit inputs; }
  # to recieve all normal flake outputs
  # best used after the default template to integrate your new neovim config
  # into an existing flake-based configuration's repository
  nix flake init -t github:BirdeeHub/nixCats-nvim#nixExpressionFlakeOutputs

  # for utilities for functionality without nix
  # added at lua/nixCatsUtils also run the following
  # at the top level of your neovim config:
  nix flake init -t github:BirdeeHub/nixCats-nvim#luaUtils
  # contains things like "is this nix?" "do this if not nix, else do that"
  # needs to be in your config at lua/nixCatsUtils,
  # because if you dont use nix to load neovim,
  # nixCats (obviously) can't provide you with anything from nix!

  # If using zsh with extra regexing, be sure to escape the #
```
This will create an empty version of flake.nix (or default.nix) for you to fill in.

It will import the utils set and thus also the builder and
help from nixCats-nvim itself.

If you added the luaUtils template, you should have that now too at [./lua/nixCatsUtils](https://github.com/BirdeeHub/nixCats-nvim/blob/main/lua/nixCatsUtils).

Re-enter the nixCats nvim version by typing `nixCats .` and take a look!
Reference the help and nixCats-nvim itself as a guide for importing your setup.
Typing `:help nixCats` without hitting enter will open up a list of help options for this scheme via auto-complete.

You add plugins to the flake.nix, call whatever setup function is required by the plugin wherever you want,
and use lspconfig to set up lsps. You may optionally choose to set up a plugin
only when that particular category is enabled in the current package by checking `nixCats('your.cats.name')` first.

see [:h nixCats](https://nixcats.org/nixCats_plugin.html) for help with the nixCats lua plugin.

It is a similar process to migrating to a new neovim plugin manager. Because you are.

Use a template and put the plugin names into the main nix file provided.

You can import them from nixpkgs or straight from your inputs via a convenience overlay [:h nixCats.flake.inputs](https://nixcats.org/nixCats_format.html)

Then configure in lua.

Use the help and the top level of the nixCats-nvim repo itself as an example (everything outside of ./nix!).
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

## Introduction <a name="introduction"></a>

This project is a heavily modified version of the wrapNeovim/wrapNeovimUnstable functions provided by nixpkgs, to allow you to get right into a working and full-featured, nix-integrated setup based on your old configuration as quickly as possible without making sacrifices in your nix that you will need to refactor out later.

All loading can be done from [flake.nix](https://github.com/BirdeeHub/nixCats-nvim/blob/main/flake.nix), with the option of custom overlays for specifc things there should you need it (rare!). Alternatively, you could import it as a module (nixos and/or home-manager)! It works the same way with either method. Then configure in the normal neovim scheme.

The first main feature is the nixCats messaging system, which means you will not need to write ANY lua within your nix files (although you still can), and thus can use all the neovim tools like lazydev that make configuring it so wonderful when configuring in your normal ~/.config/nvim

Nix is for downloading and should stay for downloading. Your lua just needs to know what it was built with and where that is.

There is no live updating from nix. Nix runs, it installs your stuff, and then it does nothing. Therefore, there is no reason you can't just write your data to a lua table in a file.

And thus nixCats was born. A system for doing just that in an effective and organized manner. It can pass anything other than nix functions, because again, nix is done by the time any lua ever executes.

The second main feature is the category system, which allows you to enable and disable categories of nvim dependencies within your nix PER NVIM PACKAGE within the SAME CONFIG DIRECTORY and have your lua know about it without any stress (thanks to the nixCats messaging system).

Both of these features are a result of the same simple innovation. Generate a lua table from a nix set, put it in a lua file that returns it, and put that in a plugin.

The name is NIX CATEGORIES but shorter. 🐱

You can use it to have as many neovim configs as you want. For direnv shells and stuff.

But its also just a normal neovim configuration installed via nix with an easy way to pass info from nix to lua so use it however you want.

Simply add plugins and lsps and stuff to lists in flake.nix, and then configure like normal!

You dont always want a plugin? Ask `nixCats("the.category")` and learn if you want to load it this time!

Want to pass info from nix to lua? Just add it to the same table in nix and then `nixCats("some.info")`.

The category scheme allows you to output many different packages with different subsets of your config.

You need a minimal python3 nvim ide in a shell, and it was a subset of your previous config? Throw some `nixCats("the.category")` at it, and enable only those in a new entry in packageDefinitions.

Want one that actually reflects lua changes without rebuilding for testing? Have 2 `packageDefinitions` with the same categories, except one has wrapRc = false and unwrappedCfgPath set. You can install them both!

It is easy to convert between all starter templates, so do not worry at the start which one to choose, all options will be available to you in any of them,
including installing multiple versions of neovim to your PATH.

However I suggest starting with the flake standalone and then using the nixExpressionFlakeOutputs template to combine your neovim into your normal system flake when you are ready to do so.

This is because the flake standalone is easy to have in its own directory somewhere to test things out, runs without nixos or home manager,
and then the nixExpressionFlakeOutputs is literally just the outputs function, and you move your inputs to your system inputs. Then you call the function with the inputs, and recieve the normal flake outputs.

They allow you to export everything this repo does, but with your config as the base.

The modules can optionally inherit category definitions from the flake you import from. This makes it easy to modify an existing neovim config in a separate nix config if required. However when using the [module](https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix/templates/module), it is harder to export the configuration separately from your main system flake for running via `nix run`, so I would generally suggest starting with one of [the](https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix/templates/nixExpressionFlakeOutputs) [other](https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix/templates/overwrite) [templates](https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix/templates/fresh).

Everything you need to make a config based on nixCats is exported by the nixCats.utils variable, the templates demonstrate usage of it and make it easy to start.

You will not be backed into any corners using the nixCats scheme, either as a flake or module.

You should make use of the in-editor help at:

[:help nixCats](https://nixcats.org/nixCats_plugin.html)

[:help nixCats.overview](https://nixcats.org/nixCats_installation.html)

[:help nixCats.flake](https://nixcats.org/nixCats_format.html)

[:help nixCats.*](https://nixcats.org/TOC.html)

The help can be viewed here directly but it is adviseable to use a nix shell to view it from within the editor.

Simply run `nix shell github:BirdeeHub/nixCats-nvim` and then run `nixCats` to open nvim and read it.

Or `nix run github:BirdeeHub/nixCats-nvim` to open it directly and type [:h nixCats](https://nixcats.org/TOC.html) without hitting enter to see the help options in the auto-complete.

This is because the vimdoc links in the help currently only work when viewed within nvim.

> An important note: if you add a file,
> nix will not package it unless you add it 
> to your git staging before you build it...
> So nvim wont be able to find it...
> So, run git add before you build.

It works as a regular config folder without any nix too using the `luaUtils` template and [help: nixCats.luaUtils](https://nixcats.org/nixCats_luaUtils.html).

`luaUtils` contains the tools and advice to adapt your favorite package managers to give your nix setup the ultimate flexibility from before of trying to download all 4 versions of rust, node, ripgrep, and fd for your overcomplicated config on a machine without using nix...

In terms of the nix code, you should not have to leave your template's equivalent of [flake.nix](https://github.com/BirdeeHub/nixCats-nvim/blob/main/flake.nix) except OCCASIONALLY [customBuildsOverlay](https://github.com/BirdeeHub/nixCats-nvim/blob/main/overlays/customBuildsOverlay.nix) when the thing you wish to install is not on nixpkgs and the standardPluginOverlay does not work.

All config folders like `ftplugin/`, `pack/` and `after/` work as designed (see `:h rtp`), if you want lazy loading put it in `optionalPlugins` in a category in the flake and call `vim.cmd('packadd <pluginName>')` from an autocommand or keybind when you want it. NOTE: `packadd` does not source `after` dirs, so to lazy load those you must source those yourself (or use the lazy.nvim wrapper in [luaUtils](https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix/nixCatsHelp/luaUtils.txt))

It runs on linux, mac, and WSL. You will need nix with flakes enabled, git, a clipboard manager of some kind, and a terminal that supports bracketed paste.
If you're not on linux you don't need to care what those last 2 things mean.
You also might want a [nerd font](https://www.nerdfonts.com/) for some icons depending on your OS, terminal, and configuration.

(full usage covered in included help files, accessible [here](https://nixcats.org/TOC.html) and in editor, but *much better viewed in-editor* because the vimdoc links work there)

If a dependency is not on nixpkgs already, you may need to add its link to the flake inputs.
If you dont know to use nix flake inputs, check [the official documentation](https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix3-flake.html#flake-inputs)
See [:h nixCats.flake.inputs](https://nixcats.org/nixCats_format.html) for
how to use the auto plugin import helper in your inputs for neovim plugins not on nixpkgs.

It is made to be customized into your own portable nix neovim distribution
with as many options as you wish, while requiring you to leave the normal
nvim configuration scheme as little as possible.

Further info for getting started:
All info I could manage to cover is covered in the included help files.
For this section,
see :help [nixCats.installation_options](https://nixcats.org/nixCats_installation.html)
and also :help [nixCats.flake.outputs.exports](https://nixcats.org/nixCats_format.html)

---

### Extra Information: <a name="outro"></a>

#### Drawbacks:

##### General nix + nvim things:

Some vscode debuggers are not on nixpkgs so you have to build them (there's a place for it in your overlays directory!) 

Let people know when you figure one out or submit it to nixpkgs. Sometimes you can extract them from vscode plugins.

##### Mason:

[Mason](https://github.com/williamboman/mason.nvim) does not work on nixOS although it does on other OS options. However you can make it work with SharedLibraries and lspsAndRuntimeDeps options if you choose to not use those fields for their intended purpose! Sometimes it can be hard to tell what dependency the error is even asking for though.

I would suggest either removing mason, or following the [example config](https://github.com/BirdeeHub/nixCats-nvim/blob/main/lua/myLuaConf/LSPs/init.lua) and [:h nixCats.LSPs](https://nixcats.org/nix_LSPS.html) by running it only when not on nix.

That way you can just add the lsp to the list in nix and move on.

But you are free to do as you wish.

##### lazy.nvim:

[Lazy.nvim](https://github.com/folke/lazy.nvim) works but unless you tell it not to reset the RTP you will lose your config directory and treesitter parsers.

There is an included wrapper that you can use to do this reset correctly and also optionally stop it from downloading stuff you already downloaded via nix.

You call that instead. It takes 2 extra arguments, and then the 2 standard lazy.setup arguments.

The first is a list of url repo name matches not to download. You can get the full set of your plugins to pass in here from nixCats.

The second is the path to lazy.nvim downloaded from nix

Then in your specs, simply fix any names that were different from nix (see `:NixCats pawsible` for the new values) and disable build statements while on nix with the `require('nixCatsUtils').lazyAdd` function

Obviously if you chose to still download the plugins via lazy you would want to keep the build statements and instead add any non-plugin dependencies they need to your nix.

Keep in mind, lazy.nvim will prevent nix from loading any plugins unless you also add it to a lazy plugin spec

#### Special mentions:

##### lz.n

[lz.n](https://github.com/nvim-neorocks/lz.n) exists and due to it working within the normal neovim plugin management scheme is better suited for managining lazy loading on nix-based configurations than lazy.nvim is.

##### For getting me started:

Many thanks to Quoteme for a great repo to teach me the basics of nix!!! I borrowed some code from it as well because I couldn't have written it better.

[utils.standardPluginOverlay](https://github.com/BirdeeHub/nixCats-nvim/blob/main/nix/utils/autoPluginOverlay.nix) is copy-pasted from [a section of Quoteme's repo.](https://github.com/Quoteme/neovim-flake/blob/34c47498114f43c243047bce680a9df66abfab18/flake.nix#L42C8-L42C8)

Thank you!!! I literally did not even know what an overlay was yet and you taught me!

I also borrowed code from nixpkgs and made modifications and improvements to better fit nixCats.

### Alternative / similar projects: <a name="alternatives"></a>

- [`kickstart.nvim`](https://github.com/nvim-lua/kickstart.nvim):
  This project was the start of my neovim journey and I would 100% suggest it over this one to anyone new to neovim.
  It does not use Nix to manage plugins. Use nixCats after this one if you want to move your version of kickstart to nix.
- [`kickstart-nix.nvim`](https://github.com/mrcjkb/kickstart-nix.nvim):
  A project that, like this one, also holds to a normal neovim config structure.
  It starts you at the basics, using the raw, wrapNeovimUnstable function with no modifications.
  If nixCats feels like it is too far from the metal for you and you want to build from the ground up,
  and you still want to be able to run it in nix shells, this is the way to go.
- [`NixVim`](https://github.com/nix-community/nixvim):
  A Neovim module scheme semi-comparable to home manager for neovim.
  They try to have a module for as many packages as they can and do a great job,
  but you can always fall back to the programs.neovim syntax if something is missing.
- [`Luca's super simple`](https://github.com/Quoteme/neovim-flake):
  Definitely the simplest example I have seen thus far. I took it and ran with it, read a LOT of docs and nixpkgs source code and then made this.
  I mentioned it above in the special mentions. As someone with no exposure to functional programming, such a simple example was absolutely fantastic.
- [`nv`](https://github.com/NicoElbers/nv):
  Focused specifically for lazy.nvim. A cool unique concept, uses a zig program to parse lazy.nvim definitions to replace urls with the plugins you put in your nix lists at build time.
  Useage is somewhat similar to the lazy.nvim wrapper of nixCats in a standalone flake template,
  but without needing to explicitly pass in a nix-provided ignore list to the wrapper in your lua code itself.
  It obviously also does not have the categories, modules, multiple packages, the overriding scheme, etc.
