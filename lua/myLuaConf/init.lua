require("myLuaConf.plugins")
require("myLuaConf.LSPs")
require('myLuaConf.format')
if nixCats('debug') then
  require('myLuaConf.debug')
end
