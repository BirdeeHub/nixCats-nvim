local M = {}

function M.restoreGrammars()
  local grammarDir = vim.g[ [[nixCats-special-rtp-entry-vimGrammarDir]] ]
  vim.cmd([[
      let runtimepath_list = split(&runtimepath, ',')
      call insert(runtimepath_list, ']] .. grammarDir .. [[', 0)
      let &runtimepath = join(runtimepath_list, ',')
  ]])
end

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

  local grammarDir = vim.g[ [[nixCats-special-rtp-entry-vimGrammarDir]] ]
  local nixCatsPath = vim.g[ [[nixCats-special-rtp-entry-nixCats]] ]

  local lazypath
  if nixCatsPath == nil then
    lazypath = regularLazyDownload()
  else

    local myNeovimPackages = vim.g[ [[nixCats-special-rtp-entry-vimPackDir]] ] .. "/pack/myNeovimPackages"
    local nixCatsConfigDir = require('nixCats').get([[nixCats_store_config_location]])

    -- the final options we want to add
    -- if loaded from nix

    -- local ourOptions = {
    --   performance = {
    --     rtp = {
    --       paths = {
    --         nixCatsPath,
    --         grammarDir,
    --       },
    --       custom_config_dir = nixCatsConfigDir,
    --     },
    --   },
    --   dev = {
    --     extra_paths = { myNeovimPackages .. "/start", myNeovimPackages .. "/opt", }
    --     patterns = M.getTableNamesOrListValues(pluginTable),
    --   }
    -- }

    if lazyCFG.performance == nil then
      lazyCFG.performance = {}
    end
    if lazyCFG.performance.rtp == nil then
      lazyCFG.performance.rtp = {}
    end

    if lazyCFG.performance.rtp.paths == nil or type(lazyCFG.performance.rtp.paths) ~= 'table' then
      lazyCFG.performance.rtp.paths = { nixCatsPath, grammarDir }
      -- lazyCFG.performance.rtp.paths = { nixCatsPath }
    else
      local pathsToInclude
      pathsToInclude = lazyCFG.performance.rtp.paths
      table.insert(pathsToInclude, #pathsToInclude + 1, nixCatsPath)
      table.insert(pathsToInclude, #pathsToInclude + 1, grammarDir)
      lazyCFG.performance.rtp.paths = pathsToInclude
    end

    -- this custom_config_dir option has not yet been added to lazy, but pr pending. Required to make this work.
    lazyCFG.performance.rtp.custom_config_dir = nixCatsConfigDir

    if lazyCFG.dev == nil then
      lazyCFG.dev = {}
    end

    -- will be removed if lazy upstream PR is accepted
    lazyCFG.dev.path = myNeovimPackages .. "/start"

    -- I would also love to add lazyCFG.dev.paths so that I can also include opt directory
    if lazyCFG.dev.extra_paths == nil or type(lazyCFG.performance.rtp.paths) ~= 'table' then
      lazyCFG.dev.extra_paths = { myNeovimPackages .. "/start", myNeovimPackages .. "/opt", }
    else
      local pathsToInclude
      pathsToInclude = lazyCFG.dev.paths
      table.insert(pathsToInclude, #pathsToInclude + 1, myNeovimPackages .. "/start")
      table.insert(pathsToInclude, #pathsToInclude + 1, myNeovimPackages .. "/opt")
      lazyCFG.dev.extra_paths = pathsToInclude
    end

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
