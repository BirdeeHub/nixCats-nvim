local M = {}

function M.mergePluginTables(table1, table2)
  return vim.tbl_extend('keep', table1, table2)
end

---used to help provide the list of plugin names for lazy wrapper.
---@param pluginTable table|string[]
---@return string[]
function M.getTableNamesOrListValues(pluginTable)
  for key, _ in pairs(pluginTable) do
    if type(key) ~= 'string' then
      return vim.tbl_values(pluginTable)
    end
    break
  end
  return vim.tbl_keys(pluginTable)
end

---lazy.nvim wrapper
---@param pluginTable table|string[]
---@param nixLazyPath string
---@param lazySpecs any
---@param lazyCFG table
function M.setup(pluginTable, nixLazyPath, lazySpecs, lazyCFG)

  local function regularLazyDownload()
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.loop.fs_stat(lazypath) then
      vim.fn.system {
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable', -- latest stable release
        lazypath,
      }
    end
    return lazypath
  end

  -- location of the nixCats plugin in the store if loaded via nixCats.
  local nixCatsPath = vim.g[ [[nixCats-special-rtp-entry-nixCats]] ]
  local lazypath
  if nixCatsPath == nil then
    lazypath = regularLazyDownload()
    vim.opt.rtp:prepend(lazypath)
  else

    -- if you were wondering where everything was after its built, its all here.
    local grammarDir = require('nixCats').pawsible.allPlugins.ts_grammar_plugin
    local myNeovimPackages = vim.g[ [[nixCats-special-rtp-entry-vimPackDir]] ] .. "/pack/myNeovimPackages"
    local nixCatsConfigDir = require('nixCats').get([[nixCats_store_config_location]])

    lazypath = nixLazyPath
    if lazypath == nil then
      lazypath = regularLazyDownload()
    end

    if type(lazyCFG) ~= "table" then
      lazyCFG = {}
    end

    if type(lazyCFG.performance) ~= 'table' then
      lazyCFG.performance = {}
    end
    if type(lazyCFG.performance.rtp) ~= 'table' then
      lazyCFG.performance.rtp = {}
    end
    -- disable lazy.nvim rtp reset
    lazyCFG.performance.rtp.reset = false
    -- do the reset without removing important stuff
    vim.opt.rtp = {
      nixCatsConfigDir,
      nixCatsPath,
      grammarDir,
      vim.fn.stdpath("data") .. "/site",
      lazypath,
      vim.env.VIMRUNTIME,
      vim.fn.fnamemodify(vim.v.progpath, ":p:h:h") .. "/lib/nvim",
      nixCatsConfigDir .. "/after",
    }

    if type(lazyCFG.dev) ~= 'table' then
      lazyCFG.dev = {}
    end

    -- lazy.nvim can now see all our nix plugins whenever dev is true
    local oldPath = lazyCFG.dev.path
    lazyCFG.dev.path = function(plugin)
      local path = nil
      if type(oldPath) == "string" and vim.fn.isdirectory(oldPath .. "/" .. plugin.name) == 1 then
        path = oldPath .. "/" .. plugin.name
      elseif type(oldPath) == "function" then
        path = oldPath(plugin)
        if type(path) ~= "string" then
          path = nil
        end
      end
      if path == nil then
        if vim.fn.isdirectory(myNeovimPackages .. "/start/" .. plugin.name) == 1 then
          path = myNeovimPackages .. "/start/" .. plugin.name
        elseif vim.fn.isdirectory(myNeovimPackages .. "/opt/" .. plugin.name) == 1 then
          path = myNeovimPackages .. "/opt/" .. plugin.name
        else
          path = "~/projects/" .. plugin.name
        end
      end
      return path
    end

    -- locally load the plugin names provided by the user's list
    if type(lazyCFG.dev.patterns) ~= 'table' then
      lazyCFG.dev.patterns = M.getTableNamesOrListValues(pluginTable)
    else
      local toInclude
      toInclude = lazyCFG.dev.patterns
      vim.list_extend(toInclude, M.getTableNamesOrListValues(pluginTable))
      lazyCFG.dev.patterns = toInclude
    end

  end

  require('lazy').setup(lazySpecs, lazyCFG)
end

return M
