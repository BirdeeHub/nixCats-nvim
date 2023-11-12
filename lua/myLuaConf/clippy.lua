
-- kickstart.nvim starts you with this. 
-- But it constantly clobbers your system clipboard whenever you delete anything.

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
-- vim.o.clipboard = 'unnamedplus'

-- So, meet clippy.lua

-- a collection of mappings to allow you to yank to clipboard using <leader>y
-- as well as a few nice paste options, and ctrl+a
-- in normal mode, it accepts motions as well.
vim.cmd([[
  function! Yank_to_clipboard(type)
    silent exec 'normal! `[v`]"+y'
    silent exec 'let @/=@"'
  endfunction
  " nmap <silent> <leader>y :set opfunc=Yank_to_clipboard<CR>g@
  " vnoremap <silent> <leader>y "+y
  " xnoremap <silent> <leader>y "+y
  " nnoremap <silent> <leader>yy "+yy
  " vnoremap <silent> <leader>yy "+yy
  " xnoremap <silent> <leader>yy "+yy
  " nnoremap <silent> <leader>Y "+yy
  " vnoremap <silent> <leader>Y "+yy 
  " xnoremap <silent> <leader>Y "+yy
  " nnoremap <silent> <C-a> gg0vG$
  " vnoremap <silent> <C-a> gg0vG$
  " xnoremap <silent> <C-a> gg0vG$
  " nnoremap <silent> <leader>p "+p
  " inoremap <silent> <C-p> <C-r>+
  " xnoremap <silent> <leader>P "_dP
]])
vim.keymap.set("n", '<leader>y', [[:set opfunc=Yank_to_clipboard<CR>g@]], { silent = true, desc = 'Yank to clipboard (accepts motions)' })
vim.keymap.set({"v", "x"}, '<leader>y', '"+y', { noremap = true, silent = true, desc = 'Yank to clipboard' })
vim.keymap.set({"n", "v", "x"}, '<leader>yy', '"+yy', { noremap = true, silent = true, desc = 'Yank line to clipboard' })
vim.keymap.set({"n", "v", "x"}, '<leader>Y', '"+yy', { noremap = true, silent = true, desc = 'Yank line to clipboard' })
vim.keymap.set({"n", "v", "x"}, '<C-a>', 'gg0vG$', { noremap = true, silent = true, desc = 'Select all' })
vim.keymap.set('n', '<leader>p', '"+p', { noremap = true, silent = true, desc = 'Paste from clipboard' })
vim.keymap.set('i', '<C-p>', '<C-r>+', { noremap = true, silent = true, desc = 'Paste from clipboard from within insert mode' })
vim.keymap.set("x", "<leader>P", '"_dP', { noremap = true, silent = true, desc = 'Paste over selection without erasing unnamed register' })

