-- NOTE: These 2 need to be set up before any plugins are loaded.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

--[[
NOTE:
if you plan to always load your nixCats via nix,
you can safely ignore this setup call,
and the require('myLuaConf.non_nix_download') call below it.
as well as the entire lua/myLuaConf/non_nix_download file.
You also won't need lua/nixCatsUtils

IF YOU DO NOT DO THIS SETUP CALL:
the result will be that, when you load this folder without using nix,
the global nixCats function which you use everywhere
to check for categories will throw an error.
This setup function will give it a default value.
Of course, if you only ever download nvim with nix, this isnt needed.]]
--[[ ----------------------------------- ]]
--[[ This setup function will provide    ]]
--[[ a default value for the nixCats('') ]]
--[[ function so that it will not throw  ]]
--[[ an error if not loaded via nixCats  ]]
--[[ ----------------------------------- ]]
require('nixCatsUtils').setup {
  non_nix_value = true,
}
-- then load the plugins via pckr
-- YOU are in charge of putting the plugin
-- urls and build steps in there, which will only be used when not on nix,
-- and you should keep any setup functions
-- OUT of that file, as they are ONLY loaded when this
-- configuration is NOT loaded via nix.
require("myLuaConf.non_nix_download")
-- OK, again, that isnt needed if you load this setup via nix, but it is an option.

--[[
NOTE: there is also a lazy.nvim wrapper which you could use instead of the pckr one.
I have chosen to demonstrate using pckr for non-nix download in the main config,
because it has much less influence on the rest of your config.

Nix puts the plugins
into the directories pckr expects them to be in,
so you just put the URLs and build steps in there, and use its opt option to do the same
thing as putting a plugin in nixCat's OptionalPlugins field.

Using the lazy.nvim wrapper is more integrated with your config.
It uses lazy for loading even when on nix.
Instead, when you use the wrapper in luaUtils template,
You will tell it which plugins nix loaded (dont worry, this is covered in the help)
and then disable the build steps when not on nix.
(
  the help for this feature is at :h nixCats.luaUtils and the kickstart-nvim template at
  nix flake init -t github:BirdeeHub/nixCats-nvim#kickstart-nvim
)
--]]

-- NOTE: outside of when you want to use the nixCats global command
-- to decide if something should be loaded, or to pass info from nix to lua,
-- thats pretty much everything specific to nixCats that
-- needs to be in your config.
-- If you dont want multiple configs and always want to load it via nix,
-- you pretty much dont need this file at all, and you also won't need
-- anything within lua/nixCatsUtils, nor will that be in the default template.
-- that directory is addable via the luaUtils template

-- ok thats enough for 1 file. Off to lua/myLuaConf/init.lua
require('myLuaConf')
