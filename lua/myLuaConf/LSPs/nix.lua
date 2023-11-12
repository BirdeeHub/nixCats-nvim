require'lspconfig'.nil_ls.setup {
  capabilities = require("myLuaConf.LSPs.caps-onattach").get_capabilities(),
  on_attach = require("myLuaConf.LSPs.caps-onattach").on_attach,
  -- settings = {
  --   nix = {
  --     formatters = {
  --       ignoreComments = true,
  --     },
  --     signatureHelp = { enabled = true },
  --   },
  --   workspace = { checkThirdParty = true },
  --   telemetry = { enabled = false },
  -- },
}
require'lspconfig'.nixd.setup {
  capabilities = require("myLuaConf.LSPs.caps-onattach").get_capabilities(),
  on_attach = require("myLuaConf.LSPs.caps-onattach").on_attach,
  -- settings = {
  --   nix = {
  --     formatters = {
  --       ignoreComments = true,
  --     },
  --     signatureHelp = { enabled = true },
  --   },
  --   workspace = { checkThirdParty = true },
  --   telemetry = { enabled = false },
  -- },
}
