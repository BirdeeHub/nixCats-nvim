local M = {}

function M.mergePluginTables(table1, table2)
  return vim.tbl_extend('keep', table1, table2)
end

-- for conditionally disabling build steps on nix, as they are done via nix
function M.lazyAdd(v, o)
  if vim.g[ [[nixCats-special-rtp-entry-nixCats]] ] ~= nil then
    return o
  else
    return v
  end
end

function M.getTableNamesOrListValues(pluginTable)
  for key, _ in pairs(pluginTable) do
    if type(key) ~= 'string' then
      return pluginTable
    end
    break
  end
  local patterns = {}
  for key, _ in pairs(pluginTable) do
    table.insert(patterns, key)
  end
  return patterns
end

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

  local nixCatsPath = vim.g[ [[nixCats-special-rtp-entry-nixCats]] ]
  local lazypath
  if nixCatsPath == nil then
    lazypath = regularLazyDownload()
  else

    local grammarDir = require('nixCats').pawsible.allPlugins.ts_grammar_plugin
    local myNeovimPackages = vim.g[ [[nixCats-special-rtp-entry-vimPackDir]] ] .. "/pack/myNeovimPackages"
    local nixCatsConfigDir = require('nixCats').get([[nixCats_store_config_location]])

    if lazyCFG.performance == nil then
      lazyCFG.performance = {}
    end
    if lazyCFG.performance.rtp == nil then
      lazyCFG.performance.rtp = {}
    end

    -- https://github.com/folke/lazy.nvim/pull/1276
    lazyCFG.performance.rtp.override_base_rtp = function(_, ME)
      return {
        nixCatsConfigDir,
        nixCatsPath,
        grammarDir,
        vim.fn.stdpath("data") .. "/site",
        ME,
        vim.env.VIMRUNTIME,
        vim.fn.fnamemodify(vim.v.progpath, ":p:h:h") .. "/lib/nvim",
        nixCatsConfigDir .. "/after",
      }
    end

    if lazyCFG.dev == nil then
      lazyCFG.dev = {}
    end

    lazyCFG.dev.path = myNeovimPackages .. "/start"

    local desired_paths = { myNeovimPackages .. "/start", myNeovimPackages .. "/opt", }

    if lazyCFG.dev.patterns == nil or type(lazyCFG.dev.patterns) ~= 'table' then
      lazyCFG.dev.patterns = M.getTableNamesOrListValues(pluginTable)
    else
      local toInclude
      toInclude = lazyCFG.dev.patterns
      vim.list_extend(toInclude, M.getTableNamesOrListValues(pluginTable))
      lazyCFG.dev.patterns = toInclude
    end

    lazypath = nixLazyPath
    if lazypath == nil then
      lazypath = regularLazyDownload()
    end

  end

  vim.opt.rtp:prepend(lazypath)

  require('lazy').setup(lazySpecs, lazyCFG)
end

return M
