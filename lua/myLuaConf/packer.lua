local isNixInstalled = require('myLuaConf.isNixCats')
if not isNixInstalled then

  local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
    if fn.empty(fn.glob(install_path)) > 0 then
      fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
      vim.cmd [[packadd packer.nvim]]
      return true
    end
    return false
  end

  local packer_bootstrap = ensure_packer()

  return require('packer').startup(function(use)
    use { 'wbthomason/packer.nvim', }
-----------------------------------------------

    use { 'joshdick/onedark.vim', }
    use { 'nvim-tree/nvim-web-devicons', }

    use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate',
      requires = {
        'nvim-treesitter/nvim-treesitter-textobjects',
      },
    }
    use {'nvim-telescope/telescope.nvim',
      requires = {
        'nvim-lua/plenary.nvim',
        { 'nvim-telescope/telescope-fzf-native.nvim', run = 'which make && make', }
      },
    }

    use { 'neovim/nvim-lspconfig',
      requires = {
        { 'williamboman/mason.nvim', },
        { 'williamboman/mason-lspconfig.nvim', },
        { 'j-hui/fidget.nvim', },
        { 'folke/neodev.nvim', },
        { 'folke/neoconf.nvim', },
      },
    }

    use { 'hrsh7th/nvim-cmp',
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
    }

    use { 'mfussenegger/nvim-dap',
      requires = {
        { 'rcarriga/nvim-dap-ui', },
        { 'theHamsta/nvim-dap-virtual-text', },
      },
    }

    use { 'm-demare/hlargs.nvim', }
    use { 'mbbill/undotree', }
    use { 'tpope/vim-fugitive', }
    use { 'tpope/vim-rhubarb', }
    use { 'tpope/vim-sleuth', }
    use { 'folke/which-key.nvim', }
    use { 'lewis6991/gitsigns.nvim', }
    use { 'nvim-lualine/lualine.nvim', }
    use { 'lukas-reineke/indent-blankline.nvim', }
    use { 'numToStr/Comment.nvim', }
    use { 'kylechui/nvim-surround',
      requires = { 'tpope/vim-repeat', },
    }
    -- use({
    --   "iamcco/markdown-preview.nvim",
    --   run = function() vim.fn["mkdp#util#install"]() end,
    -- })

    use({ "iamcco/markdown-preview.nvim", run = "cd app && npm install", setup = function() vim.g.mkdp_filetypes = { "markdown" } end, ft = { "markdown" }, })


    -----------------------------
    -- Automatically set up your configuration after cloning packer.nvim
    -- Put this at the end after all plugins
    if packer_bootstrap then
      require('packer').sync()
    end
  end)
end
