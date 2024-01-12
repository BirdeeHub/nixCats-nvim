local M = {}
M.cats = require('nixCats.cats')
M.pawsible = require('nixCats.included')

-- will return the nearest parent category value, unless the nearest
-- parent is a table, in which case that means a different subcategory
-- was enabled but this one was not. In that case it returns nil.
function M.get(input)
    local strtable
    if type(input) == "table" then
        strtable = input
    elseif type(input) == "string" then
        local keys = {}
        for key in input:gmatch("([^%.]+)") do
            table.insert(keys, key)
        end
        strtable = keys
    else
        print("get function requires a table of strings or a dot separated string")
        return
    end
    package.loaded.nixCats.cats = nil
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

    vim.api.nvim_create_user_command('Pawsibile',
    [[lua print(vim.inspect(require('nixCats.included')))]] ,
    { desc = 'All the plugins' })

    require('_G').nixCats = M.get
end

return M
