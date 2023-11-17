-- Copyright (c) 2023 BirdeeHub 
-- Licensed under the MIT license 
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
require("myLuaConf.genericKeymaps")
require("myLuaConf.clippy")
require("myLuaConf.plugins")
require("myLuaConf.LSPs")
if require('nixCats').debug then
  require('myLuaConf.debug')
end
require("myLuaConf.opts")
