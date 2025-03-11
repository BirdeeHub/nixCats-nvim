--[[
  This directory is the luaUtils template.
  You can choose what things from it that you would like to use.
  And then delete the rest.
  Everything in this directory is optional.
--]]

local M = {}
-- A nixCats specific lze handler that you can use to conditionally enable by category easier.
-- at the start of your config, register with
-- require('lze').register_handlers(require('nixCatsUtils.lzUtils').for_cat)
-- before any calls to require('lze').load using the handler have been made.
-- accepts:
-- for_cat = { "your" "cat" };
-- for_cat = { cat = { "your" "cat" }, default = bool }
-- for_cat = "your.cat";
-- for_cat = { cat = "your.cat", default = bool }
-- where default is an alternate value for when nixCats was NOT used to install the config
M.for_cat = {
    spec_field = "for_cat",
    set_lazy = false,
    modify = function(plugin)
        if type(plugin.for_cat) == "table" and plugin.for_cat.cat ~= nil then
            if vim.g[ [[nixCats-special-rtp-entry-nixCats]] ] ~= nil then
                plugin.enabled = nixCats(plugin.for_cat.cat) or false
            else
                plugin.enabled = plugin.for_cat.default
            end
        else
            plugin.enabled = nixCats(plugin.for_cat) or false
        end
        return plugin
    end,
}

return M
