local M = {}

  function M.lazyBuild(v)
    if require('nixCatsUtils').isNixCats() then
      return nil
    else
      return v
    end
  end

  function M.getPluginPatterns(pluginTable)
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

function M.setup(pluginTable, lazySpecs, lazyCFG)

  local function regularLazyDownload()
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    -- get the lazypath from Lazy-Nix-Helper
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

  local lazypath
  local pathsToInclude
  local nixCatsPath = vim.g[ [[nixCats-special-rtp-entry-nixCats]] ]
  if nixCatsPath == nil then
    lazypath = regularLazyDownload()
  else

    if lazyCFG.performance == nil then
      lazyCFG.performance = {}
    end
    if lazyCFG.performance.rtp == nil then
      lazyCFG.performance.rtp = {}
    end
    if lazyCFG.dev == nil then
      lazyCFG.dev = {}
    end
    if lazyCFG.performance.rtp.paths ~= nil
      and type(lazyCFG.performance.rtp.paths) == 'table' then
      pathsToInclude = lazyCFG.performance.rtp.paths
      table.insert(pathsToInclude, #pathsToInclude + 1, vim.g[ [[nixCats-special-rtp-entry-vimGrammarDir]] ])
    end
    -- this custom_config_dir option has not yet been added to lazy, but pr pending. Required to make this work.
    lazyCFG.performance.rtp.custom_config_dir = require('nixCats').get([[nixCats_store_config_location]])

    -- I would also love to add lazyCFG.dev.paths so that I can also include opt directory
    lazyCFG.dev.path = vim.g[ [[nixCats-special-rtp-entry-vimPackDir]] ] .. "/pack/myNeovimPackages/start"

    lazyCFG.dev.patterns = M.getPluginPatterns(pluginTable)
    lazypath = pluginTable[ [[lazy.nvim]] ]
    if lazypath == nil then
      lazypath = regularLazyDownload()
    end

  end

  -- TODO add nixCats to lazySpecs before sending it on
  -- require('nixCats.globalCats')

  vim.opt.rtp:prepend(lazypath)

  -- [[ Configure plugins ]]
  -- NOTE: Here is where you install your plugins.
  --  You can configure plugins using the `config` key.
  --
  --  You can also configure plugins after the setup call,
  --    as they will be available in your neovim runtime.
  require('lazy').setup(lazySpecs, lazyCFG)
end

return M
