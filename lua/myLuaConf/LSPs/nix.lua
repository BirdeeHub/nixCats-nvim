require'lspconfig'.nil_ls.setup {
  capabilities = require("myLuaConf.LSPs.caps-onattach").get_capabilities(),
  on_attach = require("myLuaConf.LSPs.caps-onattach").on_attach,
}
require'lspconfig'.nixd.setup {
  capabilities = require("myLuaConf.LSPs.caps-onattach").get_capabilities(),
  on_attach = require("myLuaConf.LSPs.caps-onattach").on_attach,
}
