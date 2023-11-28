vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.opt.list = true
vim.o.hlsearch = false
vim.wo.number = true
vim.o.mouse = 'a'
vim.o.smarttab = true
vim.o.smartindent = true
vim.o.indentexpr = true
vim.o.autoindent = true
vim.o.cpoptions = 'I'
vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.wo.signcolumn = 'yes'
vim.wo.relativenumber = true
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.completeopt = 'menu,preview,noselect'
vim.o.termguicolors = true
vim.diagnostic.config { float = { border = "single" }, }
vim.wo.fillchars='eob: '
vim.o.statuscolumn = "%C%s%l "

vim.api.nvim_create_autocmd("FileType", {
  desc = "remove formatoptions",
  callback = function()
    vim.opt.formatoptions:remove({ "c", "r", "o" })
  end,
})
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
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = 'Moves Line Down' })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = 'Moves Line Up' })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = 'Scroll Down' })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = 'Scroll Up' })
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

-- these 3 jankily fix which-key related errors for some reason
vim.keymap.set('n', '<C-W>', '<c-w>', { desc = '+window'})
vim.keymap.set({"n", "v", "x"}, '"', '"', { desc = '+registers'})
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })


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
vim.keymap.set('i', '<C-p>', '<C-r>+', { noremap = true, silent = true, desc = 'Paste from clipboard from within insert mode' })
vim.keymap.set("x", "<leader>P", '"_dP', { noremap = true, silent = true, desc = 'Paste over selection without erasing unnamed register' })

vim.cmd([[highlight bstarDark ctermbg=0 guifg=#22222B]])
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
require('bstar')
