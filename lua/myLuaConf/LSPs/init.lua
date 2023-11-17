-- Copyright (c) 2023 BirdeeHub 
-- Licensed under the MIT license 
local categories = require('nixCats')
if (categories.neonixdev) then
  require('neodev').setup({})
  require("myLuaConf.LSPs.nix")
  require("myLuaConf.LSPs.lua")
end
if (categories.lspDebugMode) then
  vim.lsp.set_log_level("debug")
end
