-- Copyright (c) 2023 BirdeeHub
-- Licensed under the MIT license
-- NOTE: first to prevent use of local fields in code injected from nix
local function init_main()
@nixCatsInitMain@
end
---@type nixCats.main
local M = {}
---@diagnostic disable-next-line: inject-field
M.init_main = init_main
local meta_tbl_get = {
    __call = function(self, attrpath)
      local strtable = {}
      if type(attrpath) == "table" then
        strtable = attrpath
      elseif type(attrpath) == "string" then
        for key in attrpath:gmatch("([^%.]+)") do
          table.insert(strtable, key)
        end
      else
        print('function requires a { "list", "of", "strings" } or a "dot.separated.string"')
        return
      end
      if #strtable == 0 then return nil end
      local tbl = self;
      for _, key in ipairs(strtable) do
        if type(tbl) ~= "table" then return nil end
        tbl = tbl[key]
      end
      return tbl
    end
}
M.cats = setmetatable(@nixCatsCats@, meta_tbl_get)
M.settings = setmetatable(@nixCatsSettings@, meta_tbl_get)
M.extra = setmetatable(@nixCatsExtra@, meta_tbl_get)
M.pawsible = setmetatable(@nixCatsPawsible@, meta_tbl_get)
M.petShop = setmetatable(@nixCatsPetShop@, meta_tbl_get)
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

---@diagnostic disable-next-line: inject-field
function M.addGlobals()

    ---@type nixCats
    _G.nixCats = M

    -- command with debug info for nixCats setups
    vim.api.nvim_create_user_command('NixCats', function(opts)
        require('nixCats.debug').command(opts)
    end, {
        desc = [[:NixCats cat path.to.value || :NixCats cat path to value || :NixCats {cats,settings,pawsible,vimPackDir,configDir,nixCatsPath,...}]],
        nargs = '*',
        complete = function (ArgLead, CmdLine, CursorPos)
            return require('nixCats.debug').complete(ArgLead, CmdLine, CursorPos)
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
    package.preload['nixCats.cats'] = M.cats
    package.preload['nixCats.pawsible'] = M.pawsible
    package.preload['nixCats.settings'] = M.settings
    package.preload['nixCats.petShop'] = M.petShop
    package.preload['nixCats.extra'] = M.extra
end

M.addGlobals()

---@type nixCats
return setmetatable(M, {
    __call = function(_, cat)
        return M.get(cat)
    end
})
