require'lspconfig'.nil_ls.setup {
  capabilities = require("LSPs.caps-onattach").get_capabilities(),
  on_attach = require("LSPs.caps-onattach").on_attach,
}
require'lspconfig'.nixd.setup {
  capabilities = require("LSPs.caps-onattach").get_capabilities(),
  on_attach = require("LSPs.caps-onattach").on_attach,
}
