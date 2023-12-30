local isNixInstalled = require('myLuaConf.isNixCats')
if not isNixInstalled then

local function bootstrap_pckr()
  local pckr_path = vim.fn.stdpath("data") .. "/pckr/pckr.nvim"

  if not vim.loop.fs_stat(pckr_path) then
    vim.fn.system({
      'git',
      'clone',
      "--filter=blob:none",
      'https://github.com/lewis6991/pckr.nvim',
      pckr_path
    })
  end

  vim.opt.rtp:prepend(pckr_path)
end

bootstrap_pckr()

require('pckr').add{

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
        { 'nvim-telescope/telescope-fzf-native.nvim', run = 'which make && make', }
      },
    },

    { 'neovim/nvim-lspconfig',
      requires = {
        { 'williamboman/mason.nvim', },
        { 'williamboman/mason-lspconfig.nvim', },
        { 'j-hui/fidget.nvim', },
        { 'folke/neodev.nvim', },
        { 'folke/neoconf.nvim', },
      },
    },

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

    { 'mfussenegger/nvim-dap',
      requires = {
        { 'rcarriga/nvim-dap-ui', },
        { 'theHamsta/nvim-dap-virtual-text', },
        { 'jay-babu/mason-nvim-dap.nvim', },
      },
    },

    { 'm-demare/hlargs.nvim', },
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

    -- { "iamcco/markdown-preview.nvim", run = "cd app && npm install", setup = function() vim.g.mkdp_filetypes = { "markdown" } end, ft = { "markdown" }, },

  }
end
