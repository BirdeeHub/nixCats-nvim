local M = {}

M.isNixCats = vim.g[ [[nixCats-special-rtp-entry-nixCats]] ] ~= nil

function M.setup(v)
    if not M.isNixCats then
        local nixCats_default_value
        if type(v) == "table" and v.non_nix_value ~= nil then
            nixCats_default_value = v.non_nix_value
        else
            nixCats_default_value = true
        end
        -- if not in nix, just make it return a boolean
        require('_G').nixCats = function(_) return nixCats_default_value end
    end
end

return M
