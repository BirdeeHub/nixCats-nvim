local isNixInstalled, _ = pcall(function() require("nixCats") end)
if not isNixInstalled then
    package.loaded.nixCats = nil
    -- if you want this to default to false, change true to false
    require('_G').nixCats = function(_) return vim.g.nixCats_pckr_default end
end
return isNixInstalled
