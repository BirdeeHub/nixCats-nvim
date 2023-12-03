require("myLuaConf.plugins")
require("myLuaConf.LSPs")
require('myLuaConf.format')
if require('nixCats').debug then
  require('myLuaConf.debug')
end
