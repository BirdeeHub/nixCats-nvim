local categories = require('nixCats')
local colorschemer = categories.colorscheme-- also schemes lualine
local hlargsColor =  '#32a88f' -- if this doesnt work for new theme, change it here

vim.cmd.colorscheme(colorschemer)

require('myLuaConf.plugins.telescope')

require('myLuaConf.plugins.treesitter')

require('myLuaConf.plugins.completion')

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
  color = hlargsColor,
})
require('Comment').setup()
  -- require('fidget').setup()
require('lualine').setup({
  options = {
    icons_enabled = false,
    theme = colorschemer,
    component_separators = '|',
    section_separators = '',
  },
  sections = {
    lualine_c = {
      {
        'filename', path = 1, status = true,
      },
      'lsp_progress',
    },
  },
})
require('nvim-surround').setup()

-- indent-blank-line
require("ibl").setup()

require('harpoon').setup()
vim.keymap.set('n', '<leader>hh', [[:lua require("harpoon.ui").toggle_quick_menu()<CR>]], { noremap = true, silent = true, desc = 'open harpoon menu' })
vim.keymap.set('n', '<leader>hm', [[:lua require("harpoon.mark").add_file()<CR>]], { noremap = true, silent = true, desc = 'add file to harpoon' })
vim.keymap.set('n', '<leader>hb', [[:lua require("harpoon.ui").nav_prev()<CR>]], { noremap = true, silent = true, desc = 'open prev harpoon' })
vim.keymap.set('n', '<leader>hn', [[:lua require("harpoon.ui").nav_next()<CR>]], { noremap = true, silent = true, desc = 'open next harpoon' })

require('gitsigns').setup({
    -- See `:help gitsigns.txt`
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
  on_attach = function(bufnr)
    vim.keymap.set('n', '<leader>gp', require('gitsigns').preview_hunk,
        { buffer = bufnr, desc = 'Preview git hunk' })

    -- don't override the built-in and fugitive keymaps
    local gs = package.loaded.gitsigns
    vim.keymap.set({ 'n', 'v' }, ']c', function()
      if vim.wo.diff then return ']c' end
      vim.schedule(function() gs.next_hunk() end)
      return '<Ignore>'
    end, { expr = true, buffer = bufnr, desc = "Jump to next hunk" })
    vim.keymap.set({ 'n', 'v' }, '[c', function()
      if vim.wo.diff then return '[c' end
      vim.schedule(function() gs.prev_hunk() end)
      return '<Ignore>'
    end, { expr = true, buffer = bufnr, desc = "Jump to previous hunk" })
  end,
})
vim.cmd([[hi GitSignsAdd guifg=#04de21]])
vim.cmd([[hi GitSignsChange guifg=#83fce6]])
vim.cmd([[hi GitSignsDelete guifg=#fa2525]])

require('which-key').setup()

-- document existing key chains
require('which-key').register {
  ['<leader>c'] = { name = '[C]ode', _ = 'which_key_ignore' },
  ['<leader>d'] = { name = '[D]ocument', _ = 'which_key_ignore' },
  ['<leader>g'] = { name = '[G]it', _ = 'which_key_ignore' },
  ['<leader>r'] = { name = '[R]ename', _ = 'which_key_ignore' },
  ['<leader>s'] = { name = '[S]earch', _ = 'which_key_ignore' },
  ['<leader>w'] = { name = '[W]orkspace', _ = 'which_key_ignore' },
  ['<leader>m'] = { name = '[M]arkdown', _ = 'which_key_ignore' },
  ['<leader>F'] = { name = '[F]ile explorer', _ = 'which_key_ignore' },
  ['<leader>h'] = { name = '[H]arpoon', _ = 'which_key_ignore' },
}
