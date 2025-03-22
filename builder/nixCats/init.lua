-- Copyright (c) 2023 BirdeeHub
-- Licensed under the MIT license
---@type nixCats.main
local M = {}
M.cats = require('nixCats.cats')
M.pawsible = require('nixCats.pawsible')
M.settings = require('nixCats.settings')
M.petShop = require('nixCats.petShop')
M.extra = require('nixCats.extra')
M.configDir = M.settings.nixCats_config_location
-- NOTE: nixCats is inside of these and thus they could not be written into nixCats
-- due to infinite recursion, so they are variables instead.
M.nixCatsPath = require('nixCats.saveTheCats')
M.vimPackDir = vim.g[ [[nixCats-special-rtp-entry-vimPackDir]] ]
M.packageBinPath = os.getenv('NVIM_WRAPPER_PATH_NIX') or vim.v.progpath

function M.get(category)
    local strtable = {}
    if type(category) == "table" then
        strtable = category
    elseif type(category) == "string" then
        for key in category:gmatch("([^%.]+)") do
            table.insert(strtable, key)
        end
    else
        print([[function requires a { "list", "of", "strings" } or a "dot.separated.string"]])
        return
    end
    ---@type any
    local cats = M.cats
    for _, key in ipairs(strtable) do
        if type(cats) ~= "table" then return cats end
        cats = cats[key]
    end
    return cats
end

function M.addGlobals()

    ---@type nixCats
    _G.nixCats = M

    local attributes = {
        "cats",
        "settings",
        "pawsible",
        "petShop",
        "extra",
        "vimPackDir",
        "configDir",
        "nixCatsPath",
        "packageBinPath",
    }
    -- command with debug info for nixCats setups
    vim.api.nvim_create_user_command('NixCats', function(opts)
        local display = vim.g.nixcats_debug_ui ~= false and require('nixCats.debug').basic_lua_popup or print

        if #opts.fargs == 0 then
            display(vim.inspect(M.cats))
            return
        elseif #opts.fargs == 1 then
            if vim.list_contains(attributes, opts.fargs[1]) then
                display(vim.inspect(M[opts.fargs[1]]))
                return
            end
        elseif #opts.fargs == 2 then
            if opts.fargs[1] == 'cat' or opts.fargs[1] == 'get' then
                display(vim.inspect(M.get(opts.fargs[2])))
                return
            end
        elseif #opts.fargs > 2 then
            local first = table.remove(opts.fargs, 1)
            if first == 'cat' or first == 'get' then
                display(vim.inspect(M.get(opts.fargs)))
                return
            end
        end
    end, {
        desc = [[:NixCats cat path.to.value || :NixCats cat path to value || :NixCats {cats,settings,pawsible,vimPackDir,configDir,nixCatsPath,...}]],
        nargs = '*',
        complete = function (ArgLead, CmdLine, CursorPos)
            return require('nixCats.debug').debug_command_complete(attributes, M.cats, ArgLead, CmdLine, CursorPos)
        end,
    })

    vim.cmd([[
        function! GetAllNixCats()
            echoerr("GetAllNixCats() is deprecated. Use GetNixCats() instead")
            return v:lua.require('nixCats.cats')
        endfunction
        function! GetNixCat(value)
            return luaeval('require("nixCats").get("' . a:value . '")')
        endfunction
        function! GetNixSettings(...)
            if a:0 == 0
                return luaeval('require("nixCats.settings")')
            else
                return luaeval('require("nixCats.settings")("' . a:1 . '")')
            endif
        endfunction
        function! GetNixExtra(...)
            if a:0 == 0
                return luaeval('require("nixCats.extra")')
            else
                return luaeval('require("nixCats.extra")("' . a:1 . '")')
            endif
        endfunction
        function! GetNixCats(...)
            if a:0 == 0
                return luaeval('require("nixCats.cats")')
            else
                return luaeval('require("nixCats.cats")("' . a:1 . '")')
            endif
        endfunction
        function! GetNixPawsible(...)
            if a:0 == 0
                return luaeval('require("nixCats.pawsible")')
            else
                return luaeval('require("nixCats.pawsible")("' . a:1 . '")')
            endif
        endfunction
        function! GetNixPetShop(...)
            if a:0 == 0
                return luaeval('require("nixCats.petShop")')
            else
                return luaeval('require("nixCats.petShop")("' . a:1 . '")')
            endif
        endfunction
    ]])
end

M.addGlobals()

---@type nixCats
return setmetatable(M, {
    __call = function(_, cat)
        return M.get(cat)
    end
})
