
-- a collection of mappings to allow you to yank to clipboard using <leader>y
-- in normal mode, it accepts motions as well, but I didn't know how to put that in which-key
vim.cmd([[
  nmap <silent> <leader>y :set opfunc=Yank_to_clipboard<CR>g@
  function! Yank_to_clipboard(type)
    silent exec 'normal! `[v`]"+y'
    silent exec 'let @/=@"'
  endfunction
]])
vim.keymap.set({"v", "x"}, '<leader>y', '"+y', { noremap = true, silent = true, desc = 'Yank to clipboard' })
vim.keymap.set({"n", "v", "x"}, '<leader>yy', '"+yy', { noremap = true, silent = true, desc = 'Yank line to clipboard' })
vim.keymap.set({"n", "v", "x"}, '<leader>Y', '"+yy', { noremap = true, silent = true, desc = 'Yank line to clipboard' })
vim.keymap.set({"n", "v", "x"}, '<C-a>', 'ggvG$', { noremap = true, silent = true, desc = 'Select all' })
vim.keymap.set('n', '<leader>p', '"+p', { noremap = true, silent = true, desc = 'Paste from clipboard' })
vim.keymap.set('i', '<C-p>', '<C-r>+', { noremap = true, silent = true, desc = 'Paste from clipboard from within insert mode' })
vim.keymap.set("x", "<leader>P", '"_dP', { desc = 'Paste from Selection' })

