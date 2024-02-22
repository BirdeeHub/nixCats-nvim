-- These 2 need to be set up before any plugins are loaded.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

--[[ ----------------------------------- ]]
--[[ THIS SETUP AND catPacker ARE FOR    ]]
--[[ pckr THE NEOVIM PLUGIN MANAGER      ]]
--[[ They do NOTHING if your config      ]]
--[[ is loaded via nix.                  ]]
--[[ ----------------------------------- ]]
--[[
if you plan to always load your nixCats via nix,
you can safely ignore this setup call,
and the require('nixCatsUtils.catPacker').setup call below it.

IF YOU DO NOT DO THIS SETUP CALL:
the result will be that, when you load this folder without using nix,
the global nixCats function which you use everywhere
to check for categories will throw an error.
This setup function will give it a default value.
Of course, if you only ever download nvim with nix, this isnt needed.]]
--[[ ----------------------------------- ]]
--[[ This setup function will provide    ]]
--[[ a default value for the nixCats('') ]]
--[[ function so that it will not throw  ]]
--[[ an error if not loaded via nixCats  ]]
--[[ ----------------------------------- ]]
require('nixCatsUtils').setup {
  non_nix_value = true,
}
-- then load the plugins via pckr
-- YOU are in charge of putting the plugin
-- urls and build steps in there,
-- and you should keep any setup functions
-- OUT of that file, as they are ONLY loaded when this
-- configuration is NOT loaded via nix.
require('nixCatsUtils.catPacker').setup({
--[[ ------------------------------------------ ]]
--[[ ### DONT USE CONFIG VARIABLE ###           ]]
--[[ unless you are ok with that instruction    ]]
--[[ not being ran when used via nix,           ]]
--[[ pckr will not be ran when using nix        ]]
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

  -- all the rest of the setup will be done using the normal setup functions later,
  -- thus working regardless of what method loads the plugins.
  -- only stuff pertaining to downloading should be added to pckr.

})

-- OK, again, that isnt needed if you load this setup via nix, but it is an option.



-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!

-- I like these. They tell me about tabs vs spaces and help me
-- visually see things. Feel free to disable.
vim.opt.list = true
vim.opt.listchars:append("space:⋅")

-- Set highlight on search
vim.o.hlsearch = false

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- Indent
-- currently being handled by treesitter
vim.o.smarttab = true
-- vim.o.smartindent = true
-- vim.o.indentexpr = true
-- vim.o.autoindent = true
vim.o.cpoptions = 'I'
-- vim.o.tabstop = 4
-- vim.o.softtabstop = 4
-- vim.o.shiftwidth = 4
vim.o.expandtab = true

-- stops line wrapping from being confusing
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = 'yes'
vim.wo.relativenumber = true

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menu,preview,noselect'

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- [[ Disable auto comment on enter ]]
-- See :help formatoptions
vim.api.nvim_create_autocmd("FileType", {
  desc = "remove formatoptions",
  callback = function()
    vim.opt.formatoptions:remove({ "c", "r", "o" })
  end,
})

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

vim.g.netrw_liststyle=0
vim.g.netrw_banner=0
-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = 'Moves Line Down' })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = 'Moves Line Up' })
-- vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = 'Scroll Down' })
-- vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = 'Scroll Up' })
vim.keymap.set("n", "n", "nzzzv", { desc = 'Next Search Result' })
vim.keymap.set("n", "N", "Nzzzv", { desc = 'Previous Search Result' })

-- see help sticky keys on windows
vim.cmd([[command! W w]])
vim.cmd([[command! Wq wq]])
vim.cmd([[command! WQ wq]])
vim.cmd([[command! Q q]])

-- opposite of A
vim.keymap.set('n','B','^i', { noremap = true, silent = true, desc = 'edit at beginning of line' })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Netrw
vim.keymap.set("n", "<leader>FF", "<cmd>Explore<CR>", { noremap = true, desc = '[F]ile[F]inder' })
vim.keymap.set("n", "<leader>Fh", "<cmd>e .<CR>", { noremap = true, desc = '[F]ile[h]ome' })


-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })


-- kickstart.nvim starts you with this. 
-- But it constantly clobbers your system clipboard whenever you delete anything.

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
-- vim.o.clipboard = 'unnamedplus'

vim.keymap.set("n", '<leader>y', '"+y', { noremap = true, silent = true, desc = 'Yank to clipboard' })
vim.keymap.set({"v", "x"}, '<leader>y', '"+y', { noremap = true, silent = true, desc = 'Yank to clipboard' })
vim.keymap.set({"n", "v", "x"}, '<leader>yy', '"+yy', { noremap = true, silent = true, desc = 'Yank line to clipboard' })
vim.keymap.set({"n", "v", "x"}, '<leader>Y', '"+yy', { noremap = true, silent = true, desc = 'Yank line to clipboard' })
vim.keymap.set({"n", "v", "x"}, '<C-a>', 'gg0vG$', { noremap = true, silent = true, desc = 'Select all' })
vim.keymap.set({'n', 'v', 'x'}, '<leader>p', '"+p', { noremap = true, silent = true, desc = 'Paste from clipboard' })
vim.keymap.set('i', '<C-p>', '<C-r><C-p>+', { noremap = true, silent = true, desc = 'Paste from clipboard from within insert mode' })
vim.keymap.set("x", "<leader>P", '"_dP', { noremap = true, silent = true, desc = 'Paste over selection without erasing unnamed register' })

-- so, my normal mode <leader>y randomly didnt accept any motions.
-- I didnt know it was meant to, because that was my first install of neovim.
-- If that ever happens to you, comment out the normal one, then uncomment this keymap and the function below it.
-- A full purge of ALL previous config files and state installed via pacman fixed it for me,
-- as the pacman config was the one that had that problem and it was infecting this one too.
-- I thought I was cool, but apparently I was doing a workaround to restore default behavior.

-- vim.keymap.set("n", '<leader>y', [[:set opfunc=Yank_to_clipboard<CR>g@]], { silent = true, desc = 'Yank to clipboard (accepts motions)' })
-- vim.cmd([[
--   function! Yank_to_clipboard(type)
--     silent exec 'normal! `[v`]"+y'
--     silent exec 'let @/=@"'
--   endfunction
--   " This fix would work in vim too if you used the following.
--   " nmap <silent> <leader>y :set opfunc=Yank_to_clipboard<CR>g@
-- ]])


-- ok thats enough for 1 file. Off to lua/myLuaConf/init.lua
require('myLuaConf')
