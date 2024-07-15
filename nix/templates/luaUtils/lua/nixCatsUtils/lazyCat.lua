local M = {}

function M.mergePluginTables(table1, table2)
  return vim.tbl_extend('keep', table1, table2)
end

---used to help provide the list of plugin names for lazy wrapper.
---@param pluginTable table|string[]|nil
---@return string[]
function M.getTableNamesOrListValues(pluginTable)
  if pluginTable == nil then
    return {}
  end
  for key, _ in pairs(pluginTable) do
    if type(key) ~= 'string' then
      return vim.tbl_values(pluginTable)
    end
    break
  end
  return vim.tbl_keys(pluginTable)
end

---lazy.nvim wrapper
---@param pluginTable table|string[]|nil
---@param nixLazyPath string|nil
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
  -- No nixCats? Not nix. Do it normally
  if nixCatsPath == nil then
    lazypath = regularLazyDownload()
    vim.opt.rtp:prepend(lazypath)
  else
  -- Else, its nix, so we wrap lazy with a few extra config options

    lazypath = nixLazyPath
    -- and also we probably dont have to download lazy either
    if lazypath == nil then
      lazypath = regularLazyDownload()
    end

    -- If you wanted to know where nixCats puts everything in its final form to be included:
    local myNeovimPackages = vim.g[ [[nixCats-special-rtp-entry-vimPackDir]] ] .. "/pack/myNeovimPackages"
    local grammarDir = require('nixCats').pawsible.allPlugins.ts_grammar_plugin
    local nixCatsConfigDir = require('nixCats').get([[nixCats_store_config_location]])

    local oldPath
    local lazypatterns
    if type(lazyCFG) == "table" and type(lazyCFG.dev) == "table" then
      if type(lazyCFG.dev.patterns) ~= 'table' then
        lazypatterns = M.getTableNamesOrListValues(pluginTable)
      else
        local toInclude = lazyCFG.dev.patterns
        vim.list_extend(toInclude, M.getTableNamesOrListValues(pluginTable))
        lazypatterns = toInclude
      end
      oldPath = lazyCFG.dev.path
    end

    local newLazyOpts = {
      performance = {
        rtp = {
          reset = false,
        },
      },
      dev = {
        path = function(plugin)
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
        end,
        patterns = lazypatterns or M.getTableNamesOrListValues(pluginTable),
      }
    }
    lazyCFG = vim.tbl_extend("force", lazyCFG or {}, newLazyOpts)

    -- do the reset we disabled without removing important stuff
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
  end

  require('lazy').setup(lazySpecs, lazyCFG)
end

return M
