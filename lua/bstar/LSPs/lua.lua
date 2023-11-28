require'lspconfig'.lua_ls.setup {
  capabilities = require("bstar.LSPs.caps-onattach").get_capabilities(),
  on_attach = require("bstar.LSPs.caps-onattach").on_attach,
  filetypes = { "lua" }, -- technically this part is not needed
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
