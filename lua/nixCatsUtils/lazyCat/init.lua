local M = {}

-- for conditionally disabling build steps on nix, as they are done via nix
function M.lazyAdd(v)
  if vim.g[ [[nixCats-special-rtp-entry-nixCats]] ] ~= nil then
    return nil
  else
    return v
  end
end

function M.getTableNamesOrListValues(pluginTable)
  for key, _ in pairs(pluginTable) do
    if type(key) == 'number' or key < 1 or key > #pluginTable then
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
    --     paths = { myNeovimPackages .. "/start", myNeovimPackages .. "/opt", }
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

    -- will be traded out for the following portion if PR is accepted
    lazyCFG.dev.path = myNeovimPackages .. "/start"

    -- I would also love to add lazyCFG.dev.paths so that I can also include opt directory
    -- if lazyCFG.dev.paths == nil or type(lazyCFG.performance.rtp.paths) ~= 'table' then
    --   lazyCFG.dev.paths = { myNeovimPackages .. "/start", myNeovimPackages .. "/opt", }
    -- else
    --   local pathsToInclude
    --   pathsToInclude = lazyCFG.dev.paths
    --   table.insert(pathsToInclude, #pathsToInclude + 1, myNeovimPackages .. "/start")
    --   table.insert(pathsToInclude, #pathsToInclude + 1, myNeovimPackages .. "/opt")
    --   lazyCFG.dev.paths = pathsToInclude
    -- end

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
