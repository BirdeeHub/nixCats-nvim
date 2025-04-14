if not nixCats('general') then
  return
end

vim.cmd.colorscheme('onedark')

vim.g.startuptime_event_width = 0
vim.g.startuptime_tries = 10
vim.g.startuptime_exe_path = nixCats.packageBinPath

require('mini.pairs').setup()
require('mini.icons').setup()
require('mini.ai').setup()

require('lualine').setup({
  options = {
    icons_enabled = false,
    theme = 'onedark',
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
    lualine_b = { 'lsp_progress', },
    lualine_z = { 'tabs' }
  },
})

require('which-key').setup({})
require('which-key').add {
  { "<leader><leader>", group = "buffer commands" },
  { "<leader><leader>_", hidden = true },
  { "<leader>c", group = "[c]ode" },
  { "<leader>c_", hidden = true },
  { "<leader>d", group = "[d]ocument" },
  { "<leader>d_", hidden = true },
  { "<leader>g", group = "[g]it" },
  { "<leader>g_", hidden = true },
  { "<leader>r", group = "[r]ename" },
  { "<leader>r_", hidden = true },
  { "<leader>s", group = "[s]earch" },
  { "<leader>s_", hidden = true },
  { "<leader>f", group = "[f]ind" },
  { "<leader>f_", hidden = true },
  { "<leader>t", group = "[t]oggles" },
  { "<leader>t_", hidden = true },
  { "<leader>w", group = "[w]orkspace" },
  { "<leader>w_", hidden = true },
}
