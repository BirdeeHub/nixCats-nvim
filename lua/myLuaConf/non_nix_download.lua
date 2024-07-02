-- load the plugins via pckr when not on nix
-- YOU are in charge of putting the plugin
-- urls and build steps in there, which will only be used when not on nix,
-- and you should keep any setup functions
-- OUT of that file, as they are ONLY loaded when this
-- configuration is NOT loaded via nix.
require('nixCatsUtils.catPacker').setup({
--[[ ------------------------------------------ ]]
--[[ ### DONT USE CONFIG VARIABLE ###           ]]
--[[ unless you are ok with that instruction    ]]
--[[ not being ran when used via nix,           ]]
--[[ pckr will not be ran when using nix        ]]
--[[                                            ]]
--[[ The way to think of this is, its very      ]]
--[[ similar to the main nix file for nixCats   ]]
--[[ It has an opt for optional plugins, and    ]]
--[[ it can be used to download your plugins.   ]]
--[[ but, we dont want to handle anything about ]]
--[[ loading those plugins here, so that we can ]]
--[[ use the same loading code that we use for  ]]
--[[ our normal nix-loaded config               ]]
--[[ we will do all our loading and configuring ]]
--[[ elsewhere in our configuration, so that    ]]
--[[ we dont have to write it twice.            ]]
--[[ ------------------------------------------ ]]
  { 'joshdick/onedark.vim', },
  { 'nvim-tree/nvim-web-devicons', },

  { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate',
    requires = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
  },
  {'nvim-telescope/telescope.nvim',
    requires = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', run = 'which make && make', },
      { 'nvim-telescope/telescope-ui-select.nvim' },
    },
  },

  { 'neovim/nvim-lspconfig',
    requires = {
      { 'williamboman/mason.nvim', },
      { 'williamboman/mason-lspconfig.nvim', },
      { 'j-hui/fidget.nvim', },
    },
  },
  --  NOTE:  we take care of lazy loading elsewhere in an autocommand
    -- so that we can use the same code on and off nix.
    -- so here we just tell it not to auto load it
  { 'folke/lazydev.nvim', cond = function(_) end, },

  { 'hrsh7th/nvim-cmp',
    requires = {
      { 'onsails/lspkind.nvim', },
      { 'L3MON4D3/LuaSnip', },
      { 'saadparwaiz1/cmp_luasnip', },
      { 'hrsh7th/cmp-nvim-lsp', },
      { 'hrsh7th/cmp-nvim-lua', },
      { 'hrsh7th/cmp-nvim-lsp-signature-help', },
      { 'hrsh7th/cmp-path', },
      { 'rafamadriz/friendly-snippets', },
      { 'hrsh7th/cmp-buffer', },
      { 'hrsh7th/cmp-cmdline', },
      { 'dmitmel/cmp-cmdline-history', },
    },
  },
  { 'mfussenegger/nvim-lint' },
  { 'stevearc/conform.nvim' },

  { 'mfussenegger/nvim-dap',
    requires = {
      { 'nvim-neotest/nvim-nio' },
      { 'rcarriga/nvim-dap-ui', },
      { 'theHamsta/nvim-dap-virtual-text', },
      { 'jay-babu/mason-nvim-dap.nvim', },
    },
  },

  { 'm-demare/hlargs.nvim', },
  { "stevearc/oil.nvim" },
  { 'mbbill/undotree', },
  { 'tpope/vim-fugitive', },
  { 'tpope/vim-rhubarb', },
  { 'tpope/vim-sleuth', },
  { 'folke/which-key.nvim', },
  { 'lewis6991/gitsigns.nvim', },
  { 'nvim-lualine/lualine.nvim', },
  { 'lukas-reineke/indent-blankline.nvim', },
  { 'numToStr/Comment.nvim', },
  { 'kylechui/nvim-surround',
    requires = { 'tpope/vim-repeat', },
  },

  {
    "iamcco/markdown-preview.nvim",
    run = function() vim.fn["mkdp#util#install"]() end,
  },

  -- all the rest of the setup will be done using the normal setup functions later,
  -- thus working regardless of what method loads the plugins.
  -- only stuff pertaining to downloading should be added to pckr.

})
-- OK, again, that isnt needed if you load this setup via nix, but it is an option.
