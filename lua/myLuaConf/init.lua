require("myLuaConf.plugins")
require("myLuaConf.LSPs")
if require('nixCats').debug then
  require('myLuaConf.format')
end
if require('nixCats').debug then
  require('myLuaConf.debug')
end
