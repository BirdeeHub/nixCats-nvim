local M = {}

M.isNixCats, _ = pcall(function() require("nixCats") end)

function M.setup(v)
    if not M.isNixCats then
        local nixCats_pckr_default
        if type(v) == "table" and v.default_cat_value ~= nil then
            nixCats_pckr_default = v.default_cat_value
        else
            nixCats_pckr_default = true
        end
        package.loaded.nixCats = nil
        -- if not in nix, just make it return a boolean
        require('_G').nixCats = function(_) return nixCats_pckr_default end
    end
end


return M
