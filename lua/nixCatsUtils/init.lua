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

function M.enableForCategory(v, default)
  if vim.g[ [[nixCats-special-rtp-entry-nixCats]] ] ~= nil or default == nil then
    if nixCats(v) then
      return true
    else
      return false
    end
  else
    return default
  end
end

-- for conditionally disabling build steps on nix, as they are done via nix
function M.lazyAdd(v, o)
  if vim.g[ [[nixCats-special-rtp-entry-nixCats]] ] ~= nil then
    return o
  else
    return v
  end
end

return M
