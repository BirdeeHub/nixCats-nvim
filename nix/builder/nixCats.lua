---@type nixCats
local M = {}
M.cats = require('nixCats.cats')
M.pawsible = require('nixCats.pawsible')
M.settings = require('nixCats.settings')
M.configDir = M.settings.nixCats_store_config_location
-- NOTE: nixCats is inside of these and thus they could not be written into nixCats
-- due to infinite recursion, so they are variables instead.
M.nixCatsPath = vim.g[ [[nixCats-special-rtp-entry-nixCats]] ]
M.vimPackDir = vim.g[ [[nixCats-special-rtp-entry-vimPackDir]] ]

package.preload["nixCats.included"] = function()
    vim.notify_once("require('nixCats.included') will be removed in favor of require('nixCats.pawsible') on 2024-09-01", vim.log.levels.WARN, { title = "NixCats Deprecation Warning" })
    return require('nixCats.pawsible')
end

---:h nixCats
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
    ---:h nixCats
    ---will return the nearest parent category value, unless the nearest
    ---parent is a table, in which case that means a different subcategory
    ---was enabled but this one was not. In that case it returns nil.
    ---@type fun(category: string|string[]): any
    function _G.nixCats(category)
        return M.get(category)
    end

    -- command with debug info for nixCats setups
    vim.api.nvim_create_user_command('NixCats', function(opts)
        if #opts.fargs == 0 then
            print(vim.inspect(require('nixCats.cats')))
            return
        elseif #opts.fargs == 1 then
            if opts.fargs[1] == 'settings' then
                print(vim.inspect(M.settings))
                return
            elseif opts.fargs[1] == 'pawsible' then
                print(vim.inspect(M.pawsible))
                return
            elseif opts.fargs[1] == 'cats' then
                print(vim.inspect(M.cats))
                return
            elseif opts.fargs[1] == 'vimPackDir' then
                print(M.vimPackDir)
                return
            elseif opts.fargs[1] == 'configDir' then
                print(M.settings.nixCats_store_config_location)
                return
            elseif opts.fargs[1] == 'nixCatsPath' then
                print(M.nixCatsPath)
                return
            end
        elseif #opts.fargs == 2 then
            if opts.fargs[1] == 'cat' then
                print(vim.inspect(nixCats(opts.fargs[2])))
                return
            end
        elseif #opts.fargs > 2 then
            local first = table.remove(opts.fargs, 1)
            if first == 'cat' then
                print(vim.inspect(nixCats(opts.fargs)))
                return
            end
        end
    end, {
        desc = [[:NixCats cat path.to.value || :NixCats cat path to value || :NixCats {cats,settings,pawsible,vimPackDir,configDir,nixCatsPath}]],
        nargs = '*',
        complete = function (ArgLead, CmdLine, CursorPos)
            local argsTyped = {}
            local cmdLineBeforeCursor = CmdLine:sub(1, CursorPos)
            for v in cmdLineBeforeCursor:gmatch("([^%s]+)") do
                table.insert(argsTyped, v)
            end
            local numSpaces = 0
            for _ in cmdLineBeforeCursor:gmatch("([%s]+)") do
                numSpaces = numSpaces + 1
            end
            local candidates = {
                "cat",
                "cats",
                "settings",
                "pawsible",
                "vimPackDir",
                "configDir",
                "nixCatsPath",
            }
            local matches = {}

            if not (#argsTyped > 1) then
                for _, candidate in ipairs(candidates) do
                    if candidate:sub(1, #ArgLead) == ArgLead then
                        table.insert(matches, candidate)
                    end
                end
            elseif argsTyped[2] == 'cat' then
                table.remove(argsTyped, 1)
                table.remove(argsTyped, 1)
                local argsSoFar = {}
                -- Split on dots or whitespace
                if #argsTyped == 1 then
                    for key in argsTyped[1]:gmatch("([^%.]+)") do
                        table.insert(argsSoFar, key)
                    end
                elseif #argsTyped > 1 then
                    argsSoFar = argsTyped
                else
                    return matches
                end
                -- Walk table till end of argsSoFar,
                -- and offer matching completion options
                local cats = require('nixCats.cats')
                for index, key in pairs(argsSoFar) do
                    if index == #argsSoFar then
                        for name, value in pairs(cats) do
                            if type(value) == "table" and name == key then
                                for k, _ in pairs(value) do
                                    table.insert(matches, k)
                                end
                                -- name ~= key and numSpaces - 2 < #argsSoFar
                                -- this is for preventing options from previous level from completing after hitting space
                                -- CmdLine:sub(CursorPos, CursorPos) ~= '.' is for the same reason but for the dot syntax
                            elseif name:sub(1, #key) == key and numSpaces - 2 < #argsSoFar and CmdLine:sub(CursorPos, CursorPos) ~= '.' then
                                table.insert(matches, name)
                            end
                        end
                    else
                        cats = cats[key]
                        if type(cats) ~= "table" then
                            break
                        end
                    end
                end
            end

            return matches
        end,
    })

    vim.api.nvim_create_user_command('NixCatsSettings', function ()
        vim.notify_once("`:NixCatsSettings` will be removed in favor of `:NixCats settings` on 2024-09-01", vim.log.levels.WARN, { title = "NixCats Deprecation Warning" })
        print(vim.inspect(require('nixCats.settings')))
    end,
    { desc = 'All the settings' })

    vim.api.nvim_create_user_command('NixCatsPawsible', function ()
        vim.notify_once("`:NixCatsPawsible` will be removed in favor of `:NixCats pawsible` on 2024-09-01", vim.log.levels.WARN, { title = "NixCats Deprecation Warning" })
        print(vim.inspect(require('nixCats.pawsible')))
    end,
    { desc = 'All the pawsible plugins' })

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
            lua vim.notify_once("`GetNixIncluded` will be removed in favor of `GetNixPawsible` on 2024-09-01", vim.log.levels.WARN, { title = "NixCats Deprecation Warning" })
            return v:lua.require('nixCats.pawsible')
        endfunction
    ]])

    vim.cmd([[
        function! GetNixPawsible()
            return v:lua.require('nixCats.pawsible')
        endfunction
    ]])
end

return M
