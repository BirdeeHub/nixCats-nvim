require('myLuaConf.opts_and_keys')
require("lze").register_handlers(require('lze.x'))
require("myLuaConf.plugins")
require("myLuaConf.LSPs")
if nixCats('debug') then
  require('myLuaConf.debug')
end
if nixCats('lint') then
  require('myLuaConf.lint')
end
if nixCats('format') then
  require('myLuaConf.format')
end
