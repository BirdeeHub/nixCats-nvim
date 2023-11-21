vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
require("myLuaConf.genericKeymaps")
require("myLuaConf.clippy")
require("myLuaConf.opts")
require("myLuaConf.plugins")
require("myLuaConf.LSPs")
if require('nixCats').debug then
  require('myLuaConf.debug')
end
