-- Copyright (c) 2023 BirdeeHub 
-- Licensed under the MIT license 
require'lspconfig'.lua_ls.setup {
  capabilities = require("myLuaConf.LSPs.caps-onattach").get_capabilities(),
  on_attach = require("myLuaConf.LSPs.caps-onattach").on_attach,
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
