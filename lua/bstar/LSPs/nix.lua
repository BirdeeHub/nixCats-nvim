require'lspconfig'.nil_ls.setup {
  capabilities = require("bstar.LSPs.caps-onattach").get_capabilities(),
  on_attach = require("bstar.LSPs.caps-onattach").on_attach,
}
require'lspconfig'.nixd.setup {
  capabilities = require("bstar.LSPs.caps-onattach").get_capabilities(),
  on_attach = require("bstar.LSPs.caps-onattach").on_attach,
}
