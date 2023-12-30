local M = {}

M.isNixCats, _ = pcall(function() require("nixCats") end)

function M.setup(v)
    if not M.isNixCats then
        if type(v) == "table" and v.default_cat_value ~= nil then
            vim.g.nixCats_pckr_default = v.default_cat_value
        else
            vim.g.nixCats_pckr_default = true
        end
        package.loaded.nixCats = nil
        -- if not in nix, just make it return a boolean
        require('_G').nixCats = function(_) return vim.g.nixCats_pckr_default end
    end
end


return M
