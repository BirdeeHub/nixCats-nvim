local categories = require('nixCats')
if (categories.neonixdev) then
  require('neodev').setup({})
  -- someone who forked me showed me about this plugin
  -- it allows our thing to have plugin library detection
  -- despite not being in our .config/nvim folder
  -- I was unaware of this plugin.
  -- https://github.com/lecoqjacob/nixCats-nvim/blob/main/.neoconf.json
  require("neoconf").setup({
    plugins = {
      lua_ls = {
        enabled = true,
        enabled_for_neovim_config = true,
      },
    },
  })
  require("bstar.LSPs.nix")
  require("bstar.LSPs.lua")
end
if (categories.lspDebugMode) then
  vim.lsp.set_log_level("debug")
end

require("lspconfig.ui.windows").default_options.border = "single"
local _border = "single"

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = _border,
})

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  border = _border,
})

vim.diagnostic.config({
  float = { border = _border },
})

require'lspconfig'.tsserver.setup {
  capabilities = require("bstar.LSPs.caps-onattach").get_capabilities(),
  on_attach = require("bstar.LSPs.caps-onattach").on_attach,
  init_options = {
    preferences = {
      disableSuggestions = true;
    }
  }
}

require'lspconfig'.tailwindcss.setup {
  capabilities = require("bstar.LSPs.caps-onattach").get_capabilities(),
  on_attach = require("bstar.LSPs.caps-onattach").on_attach,
}
