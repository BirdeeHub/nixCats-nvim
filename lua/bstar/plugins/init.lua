local categories = require('nixCats')

vim.cmd.colorscheme(require('nixCats').colorscheme)

require('bstar.plugins.telescope')
require('bstar.plugins.treesitter')
require('bstar.plugins.completion')
require('bstar.plugins.lualine')
require('bstar.plugins.oil')
require('bstar.plugins.rose-pine')
require('bstar.plugins.git-signs')
require('bstar.plugins.harpoon')
require('bstar.plugins.which-key')
require('bstar.plugins.ibl')
require('bstar.plugins.mini-indentscope')
require('bstar.plugins.conform')
require('bstar.plugins.trouble')
require('bstar.plugins.chatgpt')

if(categories.markdown) then
  vim.g.mkdp_auto_close = 0
  vim.keymap.set('n','<leader>mp','<cmd>MarkdownPreview <CR>',{ noremap = true, desc = 'markdown preview' })
  vim.keymap.set('n','<leader>ms','<cmd>MarkdownPreviewStop <CR>',{ noremap = true, desc = 'markdown preview stop' })
  vim.keymap.set('n','<leader>mt','<cmd>MarkdownPreviewToggle <CR>',{ noremap = true, desc = 'markdown preview toggle' })
end

vim.keymap.set('n', '<leader>U', vim.cmd.UndotreeToggle, { desc = "Undo Tree" })
vim.g.undotree_WindowLayout = 1
vim.g.undotree_SplitWidth = 40

require('hlargs').setup({
  color = '#32a88f',
})
require('Comment').setup()
require('fidget').setup()
require('nvim-surround').setup()
require("colorizer").setup({
  user_default_options = {
    tailwind = true;
  }
})
