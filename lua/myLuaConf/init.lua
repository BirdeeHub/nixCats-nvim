require("myLuaConf.plugins")
require("myLuaConf.LSPs")
require('myLuaConf.format')
if require('nixCats').get('debug') then
  require('myLuaConf.debug')
end
