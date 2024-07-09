---@type nixCats
local M = {}
M.cats = require('nixCats.cats')
M.pawsible = require('nixCats.included')
M.settings = require('nixCats.settings')

---will return the nearest parent category value, unless the nearest
---parent is a table, in which case that means a different subcategory
---was enabled but this one was not. In that case it returns nil.
---@param category string|string[]
---@return any
function M.get(category)
    local strtable
    if type(category) == "table" then
        strtable = category
    elseif type(category) == "string" then
        local keys = {}
        for key in category:gmatch("([^%.]+)") do
            table.insert(keys, key)
        end
        strtable = keys
    else
        print("get function requires a table of strings or a dot separated string")
        return
    end
    ---@type any
    local cats = require('nixCats.cats')
    for _, key in ipairs(strtable) do
        if type(cats) == "table" then
            cats = cats[key]
        else
            return cats
        end
    end

    return cats
end

function M.addGlobals()
    vim.api.nvim_create_user_command('NixCats',
    [[lua print(vim.inspect(require('nixCats.cats')))]] ,
    { desc = 'So Cute!' })

    vim.api.nvim_create_user_command('NixCatsSettings',
    [[lua print(vim.inspect(require('nixCats.settings')))]] ,
    { desc = 'All the settings' })

    vim.api.nvim_create_user_command('NixCatsPawsibile',
    [[lua print(vim.inspect(require('nixCats.included')))]] ,
    { desc = 'All the plugins' })

    ---will return the nearest parent category value, unless the nearest
    ---parent is a table, in which case that means a different subcategory
    ---was enabled but this one was not. In that case it returns nil.
    ---@type fun(category: string|string[]): any
    function _G.nixCats(category)
        return M.get(category)
    end

    vim.cmd([[
        function! GetNixCat(value)
            return luaeval('require("nixCats").get("' . a:value . '")')
        endfunction
    ]])

    vim.cmd([[
        function! GetNixSettings()
            return v:lua.require('nixCats.settings')
        endfunction
    ]])

    vim.cmd([[
        function! GetAllNixCats()
            return v:lua.require('nixCats.cats')
        endfunction
    ]])

    vim.cmd([[
        function! GetNixIncluded()
            return v:lua.require('nixCats.included')
        endfunction
    ]])
end

return M
