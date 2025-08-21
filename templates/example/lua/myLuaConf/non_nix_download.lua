-- load the plugins via vim.pack.add when not on nix
-- YOU are in charge of putting the plugin
-- urls and build steps in here, which will only be used when not on nix.
-- and you should keep any setup functions OUT of this file

-- again, you dont need this file if you only use nix to load the config,
-- this is a fallback only, and is optional.
if not require("nixCatsUtils").isNixCats then
  -- OK, again, that isnt needed if you load this setup via nix, but it is an option.

  -- NOTE: some boilerplate for providing spec.data.run instructions to build plugins
  -- Hopefully they will add some sort of built in way for building plugins.
  local augroup = vim.api.nvim_create_augroup('most_basic_build_system', { clear = false })
  vim.api.nvim_create_autocmd('PackChanged', {
    group = augroup,
    pattern = "*",
    callback = function(e)
      local p = e.data
      local run_task = (p.spec.data or {}).run
      if p.kind ~= "delete" and type(run_task) == 'function' then
        pcall(run_task, p)
      end
    end,
  })
  -- and to add an opt field to control if it gets loaded at startup or not.
  -- this will be provided in the opts table at the end of our vim.pack.add call.
  load = function(p)
    if not (p.spec.data or {}).opt then
      vim.cmd.packadd(p.spec.name)
    end
  end
  --[[ ------------------------------------------ ]]
  --[[ The way to think of this is, its very      ]]
  --[[ similar to the main nix file for nixCats   ]]
  --[[                                            ]]
  --[[ It can be used to download your plugins,   ]]
  --[[ and it has an opt for optional plugins.    ]]
  --[[                                            ]]
  --[[ We dont want to handle anything about      ]]
  --[[ loading those plugins here, so that we can ]]
  --[[ use the same loading code that we use for  ]]
  --[[ our normal nix-loaded config.              ]]
  --[[ we will do all our loading and configuring ]]
  --[[ elsewhere in our configuration, so that    ]]
  --[[ we dont have to write it twice.            ]]
  --[[ ------------------------------------------ ]]
  vim.pack.add({
    { src = "https://github.com/BirdeeHub/lze", },
    { src = "https://github.com/BirdeeHub/lzextras", },
    { src = "https://github.com/stevearc/oil.nvim", },
    { src = 'https://github.com/joshdick/onedark.vim', },
    { src = 'https://github.com/nvim-tree/nvim-web-devicons', },
    { src = 'https://github.com/nvim-lua/plenary.nvim', },
    { src = 'https://github.com/tpope/vim-repeat', },
    { src = 'https://github.com/rcarriga/nvim-notify', },

    { src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects', data = { opt = true, }, },
    {
      src = 'https://github.com/nvim-treesitter/nvim-treesitter',
      data = {
        run = function(_) vim.cmd 'TSUpdate' end,
        opt = true,
      },
    },

    {
      src = 'https://github.com/nvim-telescope/telescope-fzf-native.nvim',
      data = {
        opt = true,
        run = function(p)
          vim.system("bash", { stdin = 'which make && cd ' .. p.spec.path .. ' && make' })
        end,
      },
    },
    { src = 'https://github.com/nvim-telescope/telescope-ui-select.nvim', data = { opt = true, }, },
    { src ='https://github.com/nvim-telescope/telescope.nvim', data = { opt = true, }, },

    -- lsp
    { src = 'https://github.com/williamboman/mason.nvim', data = { opt = true, }, },
    { src = 'https://github.com/williamboman/mason-lspconfig.nvim', data = { opt = true, }, },
    { src = 'https://github.com/j-hui/fidget.nvim', data = { opt = true, }, },
    { src = 'https://github.com/neovim/nvim-lspconfig', data = { opt = true, }, },

    --  NOTE:  we take care of lazy loading elsewhere in an autocommand
      -- so that we can use the same code on and off nix.
      -- so here we just tell it not to auto load it
    { src = 'https://github.com/folke/lazydev.nvim', data = { opt = true, }, },

    -- completion
    { src = 'https://github.com/L3MON4D3/LuaSnip', name = "luasnip", data = { opt = true, }, },
    { src = 'https://github.com/hrsh7th/cmp-cmdline', data = { opt = true, }, },
    { src = 'https://github.com/Saghen/blink.cmp', data = { opt = true, }, },
    { src = 'https://github.com/Saghen/blink.compat', data = { opt = true, }, },
    { src = 'https://github.com/xzbdmw/colorful-menu.nvim', data = { opt = true, }, },

    -- lint and format
    { src = 'https://github.com/mfussenegger/nvim-lint', data = { opt = true, }, },
    { src = 'https://github.com/stevearc/conform.nvim', data = { opt = true, }, },

    -- dap
    { src = 'https://github.com/nvim-neotest/nvim-nio', data = { opt = true, }, },
    { src = 'https://github.com/rcarriga/nvim-dap-ui', data = { opt = true, }, },
    { src = 'https://github.com/theHamsta/nvim-dap-virtual-text', data = { opt = true, }, },
    { src = 'https://github.com/jay-babu/mason-nvim-dap.nvim', data = { opt = true, }, },
    { src = 'https://github.com/mfussenegger/nvim-dap', data = { opt = true, }, },

    { src = 'https://github.com/mbbill/undotree', data = { opt = true, }, },
    { src = 'https://github.com/tpope/vim-fugitive', data = { opt = true, }, },
    { src = 'https://github.com/tpope/vim-rhubarb', data = { opt = true, }, },
    { src = 'https://github.com/tpope/vim-sleuth', data = { opt = true, }, },
    { src = 'https://github.com/folke/which-key.nvim', data = { opt = true, }, },
    { src = 'https://github.com/lewis6991/gitsigns.nvim', data = { opt = true, }, },
    { src = 'https://github.com/nvim-lualine/lualine.nvim', data = { opt = true, }, },
    { src = 'https://github.com/lukas-reineke/indent-blankline.nvim', data = { opt = true, }, },
    { src = 'https://github.com/numToStr/Comment.nvim', name = "comment.nvim", data = { opt = true, }, },
    { src = 'https://github.com/kylechui/nvim-surround', data = { opt = true, }, },
    {
      src = "https://github.com/iamcco/markdown-preview.nvim",
      data = {
        run = function(_) vim.cmd "call mkdp#util#install()" end,
        opt = true,
      },
    },

    -- all the rest of the setup will be done using the normal setup functions later,
    -- thus working regardless of what method loads the plugins.
    -- only stuff pertaining to downloading and building should be added here.

  }, { load = load })
end
