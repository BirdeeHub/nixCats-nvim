local M = {}

M.isNixCats = function()
    if vim.g[ [[nixCats-special-rtp-entry-nixCats]] ] == nil then
        return false
    else
        return true
    end
end

function M.setup(v)
    if not M.isNixCats then
        local nixCats_default_value
        if type(v) == "table" and v.default_cat_value ~= nil then
            nixCats_default_value = v.default_cat_value
        else
            nixCats_default_value = true
        end
        -- if not in nix, just make it return a boolean
        require('_G').nixCats = function(_) return nixCats_default_value end
    end
end

function M.getPrefixed(table, prefix)
    -- "^vimplugin%-treesitter%-grammar%-"
    if type(table) ~= "table" then
        return
    end
    local grammarTable = {}
    for k, v in pairs(table) do
        if string.match(k, "^" .. prefix) then
            grammarTable[k] = v
        end
    end
    return grammarTable
end


return M
