
-- NOTE: various, non-plugin config
require('myLuaConf.opts_and_keys')

-- NOTE: register the extra lze handlers because we want to use them.
require("lze").register_handlers(require('lze.x'))
-- NOTE: also add another one that makes enabling a spec for a category nicer
require("lze").register_handlers(require('nixCatsUtils.lzUtils').for_cat)

-- NOTE: general plugins
require("myLuaConf.plugins")

-- NOTE: obviously, more plugins, but more organized by what they do below

-- I dont need to explain why this is called lsp right?
require("myLuaConf.LSPs")

-- NOTE: we even ask nixCats if we included our debug stuff in this setup! (we didnt)
-- But we have a good base setup here as an example anyway!
if nixCats('debug') then
  require('myLuaConf.debug')
end
-- NOTE: we included these though! Or, at least, the category is enabled.
-- these contain nvim-lint and conform setups.
if nixCats('lint') then
  require('myLuaConf.lint')
end
if nixCats('format') then
  require('myLuaConf.format')
end
-- NOTE: I didnt actually include any linters or formatters in this configuration,
-- but it is enough to serve as an example.
