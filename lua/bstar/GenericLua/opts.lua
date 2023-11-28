vim.opt.list = true
vim.o.hlsearch = true
vim.wo.number = true
vim.opt.cursorline = true
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
vim.diagnostic.config { float = { border = "single" }, }
vim.wo.fillchars='eob: '
vim.o.statuscolumn = "%C%s%l "
