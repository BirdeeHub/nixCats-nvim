local colorschemeName = nixCats('colorscheme')
if not require('nixCatsUtils').isNixCats then
  colorschemeName = 'onedark'
end
vim.cmd.colorscheme(colorschemeName)

require('myLuaConf.plugins.telescope')

require('myLuaConf.plugins.treesitter')

require('myLuaConf.plugins.completion')

if nixCats('markdown') then
  vim.g.mkdp_auto_close = 0
  vim.keymap.set('n','<leader>mp','<cmd>MarkdownPreview <CR>',{ noremap = true, desc = 'markdown preview' })
  vim.keymap.set('n','<leader>ms','<cmd>MarkdownPreviewStop <CR>',{ noremap = true, desc = 'markdown preview stop' })
  vim.keymap.set('n','<leader>mt','<cmd>MarkdownPreviewToggle <CR>',{ noremap = true, desc = 'markdown preview toggle' })
end

vim.keymap.set('n', '<leader>U', vim.cmd.UndotreeToggle, { desc = "Undo Tree" })
vim.g.undotree_WindowLayout = 1
vim.g.undotree_SplitWidth = 40

require('hlargs').setup {
  color = '#32a88f',
}
vim.cmd([[hi clear @lsp.type.parameter]])
vim.cmd([[hi link @lsp.type.parameter Hlargs]])
require('Comment').setup()
require('lualine').setup({
  options = {
    icons_enabled = false,
    theme = colorschemeName,
    component_separators = '|',
    section_separators = '',
  },
  sections = {
    lualine_c = {
      {
        'filename', path = 1, status = true,
      },
    },
  },
  inactive_sections = {
    lualine_b = {
      {
        'filename', path = 3, status = true,
      },
    },
    lualine_x = {'filetype'},
  },
  tabline = {
    lualine_a = { 'buffers' },
    -- if you use lualine-lsp-progress, I have mine here instead of fidget
    -- lualine_b = { 'lsp_progress', },
    lualine_z = { 'tabs' }
  },
})
require('fidget').setup({})

require('nvim-surround').setup()

-- indent-blank-line
require("ibl").setup()

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
    local gs = package.loaded.gitsigns

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- Navigation
    map({ 'n', 'v' }, ']c', function()
      if vim.wo.diff then
        return ']c'
      end
      vim.schedule(function()
        gs.next_hunk()
      end)
      return '<Ignore>'
    end, { expr = true, desc = 'Jump to next hunk' })

    map({ 'n', 'v' }, '[c', function()
      if vim.wo.diff then
        return '[c'
      end
      vim.schedule(function()
        gs.prev_hunk()
      end)
      return '<Ignore>'
    end, { expr = true, desc = 'Jump to previous hunk' })

    -- Actions
    -- visual mode
    map('v', '<leader>hs', function()
      gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
    end, { desc = 'stage git hunk' })
    map('v', '<leader>hr', function()
      gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
    end, { desc = 'reset git hunk' })
    -- normal mode
    map('n', '<leader>gs', gs.stage_hunk, { desc = 'git stage hunk' })
    map('n', '<leader>gr', gs.reset_hunk, { desc = 'git reset hunk' })
    map('n', '<leader>gS', gs.stage_buffer, { desc = 'git Stage buffer' })
    map('n', '<leader>gu', gs.undo_stage_hunk, { desc = 'undo stage hunk' })
    map('n', '<leader>gR', gs.reset_buffer, { desc = 'git Reset buffer' })
    map('n', '<leader>gp', gs.preview_hunk, { desc = 'preview git hunk' })
    map('n', '<leader>gb', function()
      gs.blame_line { full = false }
    end, { desc = 'git blame line' })
    map('n', '<leader>gd', gs.diffthis, { desc = 'git diff against index' })
    map('n', '<leader>gD', function()
      gs.diffthis '~'
    end, { desc = 'git diff against last commit' })

    -- Toggles
    map('n', '<leader>tb', gs.toggle_current_line_blame, { desc = 'toggle git blame line' })
    map('n', '<leader>td', gs.toggle_deleted, { desc = 'toggle git show deleted' })

    -- Text object
    map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = 'select git hunk' })
  end,
})
vim.cmd([[hi GitSignsAdd guifg=#04de21]])
vim.cmd([[hi GitSignsChange guifg=#83fce6]])
vim.cmd([[hi GitSignsDelete guifg=#fa2525]])

require("oil").setup({
  columns = {
    "icon",
    "permissions",
    "size",
    -- "mtime",
  },
  keymaps = {
    ["g?"] = "actions.show_help",
    ["<CR>"] = "actions.select",
    ["<C-s>"] = "actions.select_vsplit",
    ["<C-h>"] = "actions.select_split",
    ["<C-t>"] = "actions.select_tab",
    ["<C-p>"] = "actions.preview",
    ["<C-c>"] = "actions.close",
    ["<C-l>"] = "actions.refresh",
    ["-"] = "actions.parent",
    ["_"] = "actions.open_cwd",
    ["`"] = "actions.cd",
    ["~"] = "actions.tcd",
    ["gs"] = "actions.change_sort",
    ["gx"] = "actions.open_external",
    ["g."] = "actions.toggle_hidden",

    -- Which-key does not like this keybind AT ALL
    -- ["g\\"] = "actions.toggle_trash",
    ["g!"] = "actions.toggle_trash",
    ["g\\"] = false,
  },
})
vim.keymap.set("n", "-", "<cmd>Oil<CR>", { noremap = true, desc = 'Open Parent Directory' })
vim.keymap.set("n", "<leader>-", "<cmd>Oil .<CR>", { noremap = true, desc = 'Open nvim root directory' })
-- Which key has kind-of a lot of bugs.
-- Nix or not, some things need to be disabled.
require('which-key').setup({
  plugins = {
    marks = true, -- shows a list of your marks on ' and `
    -- BUGGED registers plugin
    registers = false, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
    -- the presets plugin, adds help for a bunch of default keybindings in Neovim
    -- No actual key bindings are created
    spelling = {
      enabled = true, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
      suggestions = 20, -- how many suggestions should be shown in the list?
    },
    presets = {
      operators = true, -- adds help for operators like d, y, ...
      motions = true, -- adds help for motions
      text_objects = true, -- help for text objects triggered after entering an operator
      -- BUGGED window control keys display
      windows = false, -- default bindings on <c-w>
      nav = true, -- misc bindings to work with windows
      z = true, -- bindings for folds, spelling and others prefixed with z
      g = true, -- bindings for prefixed with g
    },
  },
  operators = { gc = "Comments", [ "<leader>y" ] = "yank to clipboard", },
  disable = {
    -- filetypes = { "oil" },
  },
})
-- I had these errors before nixos, but I fixed them in a dumb way.
-- I simply bound them again myself and it mostly worked...
-- this is the better way to prevent the errors.

-- document existing key chains
require('which-key').register {
  ['<leader>c'] = { name = '[c]ode', _ = 'which_key_ignore' },
  ['<leader>d'] = { name = '[d]ocument', _ = 'which_key_ignore' },
  ['<leader>g'] = { name = '[g]it', _ = 'which_key_ignore' },
  ['<leader>r'] = { name = '[r]ename', _ = 'which_key_ignore' },
  ['<leader>s'] = { name = '[s]earch', _ = 'which_key_ignore' },
  ['<leader>w'] = { name = '[w]orkspace', _ = 'which_key_ignore' },
  ['<leader>m'] = { name = '[m]arkdown', _ = 'which_key_ignore' },
  ['<leader>t'] = { name = '[t]oggles', _ = 'which_key_ignore' },
  ['<leader><leader>'] = { name = 'buffer commands', _ = 'which_key_ignore' },
}
