# nixCats-nvim: A Luanatic's kickstarter flake

This is a kickstarter style repo.

It is aimed at people who know enough lua 

to comfortably proceed from a kickstarter level setup

who want to swap to using nix while still using lua.

It allows for project specific packaging using nixCats.

And for 95% of plugins, you wont need to do more than add plugins to lists,

then configure in lua using the regular setup or config functions provided.

[:help nixCats](./nixCatsHelp/nixCats.txt)

[:help nixCats.flake](./nixCatsHelp/nixCatsFlake.txt)

[:help nixCats.flake.nixperts](./nixCatsHelp/nvimBuilder.txt)

#### Introduction:
 
```
The mission: 
    Replace lazy and mason with nix, keep everything else in lua. 
    Still allow project specific packaging.

The solution: 
    Include the flake itself as a plugin
    Create nixCats so the lua may know what categories are packaged
    Also I added some really nice copy paste keybinds
    You may optionally have your config in your normal directory as well.
        (You will still be able to reference nixCats and the help should you do this.)
```

#### These are the reasons I wanted to do it this way: 

    The setup instructions for new plugins are all in Lua so translating them is effort.
    
    I didnt want to be forced into creating a new lua file for every plugin.
    
    I wanted my neovim config to be neovim flavored 
        (so that I can take advantage of all the neovim dev tools with minimal fuss)

    I still wanted my config to know what plugins and LSPs I included in the package
        so I created nixCats

All folders work, if you want lazy loading put it in optionalPlugins in a category and call packadd when you want it.

You will need nix with flakes enabled, a clipboard manager of some kind, and a terminal that supports bracketed paste

#### Basic usage:

(full usage covered in included help files, accessible here and inside neovim)

You install the plugins/LSP/debugger/program using nix, by adding them to a category in the flake (or creating a new category for it!)

You may need to add their link to the flake inputs or overlays section if they are not on nixpkgs already.

You then choose what categories to include in the flake.

You then set them up in your lua, using the default methods to do so, no more translating to your package manager!

You can optionally ask what categories you have, whenever you require nixCats

If you encounter any build steps that are not well handled by nixpkgs, 
or you need to import a plugin straight from git that has a non-standard build step,
and need to do a custom definition, [./customPluginOverlay.nix](./customPluginOverlay.nix) is the place for it.

#### Special mentions:

Many thanks to Quoteme for a great repo to teach me the basics of nix!!! I borrowed some code from it as well because I couldn't have written it better yet.

[pluginOverlay](./nix/pluginOverlay.nix) is a file copy pasted from [a section of Quoteme's repo.](https://github.com/Quoteme/neovim-flake/blob/34c47498114f43c243047bce680a9df66abfab18/flake.nix#L42C8-L42C8)

Thank you!!! It taught me both about an overlay's existence and how it works.

I also borrowed some code from nixpkgs and included links.

#### Issues:

I haven't been able to connect a debugger to dap or dap ui yet, but installing the stuff in nix is the easy part of that. I'm struggling with the lua...

dap, dap-ui, and dap-virtual-text are all already on nixpkgs, as are most if not all of the debuggers. I just have to connect them....

As such, I have included the config I've been using for dap, dap-ui and dap-virtual-text which all work but I have not enabled the categories for them.
