vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
require("GenericLua")
require("plugins")
require("LSPs")
if require('nixCats').debug then
  require('nvimDebug')
end
