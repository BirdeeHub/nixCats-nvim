local M = {}

M.isNixCats = function()
    local callSuccess, _ = pcall(function() require("nixCats") end)
    if callSuccess then
        return true
    elseif vim.g[ [[nixCats-special-rtp-entry-nixCats]] ] ~= nil then
        M.restoreNixCats()
        return true
    else
        return false
    end
end

function M.setup(v)
    if not M.isNixCats then
        local nixCats_pckr_default
        if type(v) == "table" and v.default_cat_value ~= nil then
            nixCats_pckr_default = v.default_cat_value
        else
            nixCats_pckr_default = true
        end
        -- if not in nix, just make it return a boolean
        require('_G').nixCats = function(_) return nixCats_pckr_default end
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

function M.restoreGrammars()
    local rtpAdditions = vim.g[ [[nixCats-special-rtp-entry-vimGrammarDir]] ]
    vim.cmd([[
      let runtimepath_list = split(&runtimepath, ',')
      call insert(runtimepath_list, ]] .. rtpAdditions .. [[, 0)
      let &runtimepath = join(runtimepath_list, ',')
    ]])
end

function M.restoreNixCats()
    local callSuccess, _ = pcall(function() require("nixCats") end)
    if not callSuccess and vim.g[ [[nixCats-special-rtp-entry-nixCats]] ] ~= nil then
        package.loaded.nixCats.globalCats = nil
        package.loaded.nixCats.cats = nil
        package.loaded.nixCats.included = nil
        package.loaded.nixCats = nil

        vim.cmd([[
          let configdir = stdpath('config')
          execute "set runtimepath-=" . configdir
          execute "set runtimepath-=" . configdir . "/after"

          let runtimepath_list = split(&runtimepath, ',')
          call insert(runtimepath_list, ]] ..
        vim.g[ [[nixCats-special-rtp-entry-nixCats]] ]
        .. [[, 0)
          let &runtimepath = join(runtimepath_list, ',')

          let configdir = ]] ..
        require('nixCats').get('nixCats_store_config_location')
        .. [[
          let runtimepath_list = split(&runtimepath, ',')
          call insert(runtimepath_list, configdir, 0)
          let &runtimepath = join(runtimepath_list, ',')
          execute "set runtimepath+=" . configdir . "/after"
          " init.lua has already been sourced. no need to do it again.
        ]])

        require('nixCats.globalCats')
    end
end

return M
