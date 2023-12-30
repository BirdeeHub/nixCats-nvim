
  -- first you should go ahead and install your dependencies
  -- you arent using nix if you are using this.
  -- this means you will have to install some stuff manually.

  -- so, you will need cmake, gcc, npm, nodejs,
  -- ripgrep, fd, <curl or wget>, and git,
  -- you will also need rustup and to run rustup toolchain install stable

  -- now you see why nix is so great. You dont have to do that every time.

  -- so, now for the stuff we can still auto install without nix:
  -- list your plugins here,

  -- ### DONT USE CONFIG VARIABLE ###
  -- unless you are ok with that instruction 
  -- not being ran when used via nix,
  -- this file will not be ran when using nix
  -- because of the following line:
if not require('nixCatsUtils').isNixCats then

  -- you can use this same method
  -- if you want to install via mason when not in nix
  -- or just, anything you want to do only when not using nix

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

    -- all the rest of the setup will be done within the normal scheme, thus working regardless of what method loads the plugins.
    -- only stuff pertaining to downloading should be added to pckr.

  }
end
