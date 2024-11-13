local M = {}

-- This directory is the luaUtils template.
-- the other 3 files are intended to be independent, but may depend on this one.
-- You will likely want at least something in this one,
-- and if you use lze or lz.n you should check out lzUtils.lua
-- but unless you use lazy.nvm or want to use pckr or rocks when not on nix, you wont need the other 2

---@type boolean
M.isNixCats = vim.g[ [[nixCats-special-rtp-entry-nixCats]] ] ~= nil

---@class nixCatsSetupOpts
---@field non_nix_value boolean|nil

---This function will setup a mock nixCats plugin when not using nix
---It will help prevent you from running into indexing errors without a nixCats plugin from nix.
---If you loaded the config via nix, it does nothing
---non_nix_value defaults to true if not provided or is not a boolean.
---@param v nixCatsSetupOpts
function M.setup(v)
  if not M.isNixCats then
    local nixCats_default_value
    if type(v) == "table" and type(v.non_nix_value) == "boolean" then
      nixCats_default_value = v.non_nix_value
    else
      nixCats_default_value = true
    end
    local mk_with_meta = function (tbl)
      return setmetatable(tbl, {
        __call = function(_, attrpath)
          local strtable = {}
          if type(attrpath) == "table" then
              strtable = attrpath
          elseif type(attrpath) == "string" then
              for key in attrpath:gmatch("([^%.]+)") do
                  table.insert(strtable, key)
              end
          else
              print("function requires a table of strings or a dot separated string")
              return
          end
          return vim.tbl_get(tbl, unpack(strtable));
        end
      })
    end
    package.preload['nixCats'] = function ()
      local ncsub = {
        get = function(_) return nixCats_default_value end,
        cats = mk_with_meta({
          nixCats_config_location = vim.fn.stdpath('config'),
          configDirName = os.getenv("NVIM_APPNAME") or "nvim",
          wrapRc = false,
        }),
        settings = mk_with_meta({
          nixCats_config_location = vim.fn.stdpath('config'),
          configDirName = os.getenv("NVIM_APPNAME") or "nvim",
          wrapRc = false,
        }),
        petShop = mk_with_meta({}),
        pawsible = mk_with_meta({
          allPlugins = {
            start = {},
            opt = {},
          },
        }),
        configDir = vim.fn.stdpath('config'),
        packageBinPath = os.getenv('NVIM_WRAPPER_PATH_NIX') or vim.v.progpath
      }
      return setmetatable(ncsub, {__call = function(_, cat) return ncsub.get(cat) end})
    end
    _G.nixCats = require('nixCats')
  end
end

---allows you to guarantee a boolean is returned, and also declare a different
---default value than specified in setup when not using nix to load the config
---@overload fun(v: string|string[]): boolean
---@overload fun(v: string|string[], default: boolean): boolean
function M.enableForCategory(v, default)
  if M.isNixCats or default == nil then
    if nixCats(v) then
      return true
    else
      return false
    end
  else
    return default
  end
end

---if nix, return value of nixCats(v) else return default
---Exists to specify a different non_nix_value than the one in setup()
---@param v string|string[]
---@param default any
---@return any
function M.getCatOrDefault(v, default)
  if M.isNixCats then
    return nixCats(v)
  else
    return default
  end
end

---for conditionally disabling build steps on nix, as they are done via nix
---I should probably have named it dontAddIfCats or something.
---@overload fun(v: any): any|nil
---Will return the second value if nix, otherwise the first
---@overload fun(v: any, o: any): any
function M.lazyAdd(v, o)
  if M.isNixCats then
    return o
  else
    return v
  end
end

---Useful for things such as vim-startuptime which must reference the wrapper's actual path
---If not using nix, this will simply return vim.v.progpath
---@type string
M.packageBinPath = os.getenv('NVIM_WRAPPER_PATH_NIX') or vim.v.progpath

return M
