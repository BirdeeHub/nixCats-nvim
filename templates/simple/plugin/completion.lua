if not nixCats('general') then
  return
end

require("blink.cmp").setup({
  -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
  -- See :h blink-cmp-config-keymap for configuring keymaps
  keymap = { preset = 'default' },
  appearance = {
    nerd_font_variant = 'mono'
  },
  signature = { enabled = true, },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
    providers = {
      path = {
        score_offset = 50,
      },
      lsp = {
        score_offset = 40,
      },
      snippets = {
        score_offset = 40,
      },
    },
  },
})
