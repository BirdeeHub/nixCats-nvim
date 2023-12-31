-- THIS SETUP AND catPacker ARE FOR
-- pckr THE NEOVIM PLUGIN MANAGER
-- They do nothing if your config is loaded via nix.

-- when using this as a normal nvim config folder
-- default_cat_value is what nixCats('anything')
-- will return.
-- you may also require myLuaConf.isNixCats
-- to determine if this was loaded as a nix config
-- you must set this here at the start
require('nixCatsUtils').setup {
  default_cat_value = true,
}

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- load the plugins via pckr
-- YOU are in charge of putting the plugin
-- urls and build steps in there,
-- and you should keep any setup functions
-- OUT of that file, as they are ONLY loaded when this
-- configuration is NOT loaded via nix.
require('nixCatsUtils.catPacker')


-- The rest of your configuration here
