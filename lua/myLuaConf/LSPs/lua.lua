require'lspconfig'.lua_ls.setup {
  capabilities = require("myLuaConf.LSPs.caps-onattach").get_capabilities(),
  on_attach = require("myLuaConf.LSPs.caps-onattach").on_attach,
  filetypes = { "lua" },
  settings = {
    Lua = {
      formatters = {
        ignoreComments = true,
      },
      signatureHelp = { enabled = true },
    },
    workspace = { checkThirdParty = true },
    telemetry = { enabled = false },
  },
}
