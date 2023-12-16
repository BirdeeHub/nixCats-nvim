local M = require('nixCats.cats')

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

return M
