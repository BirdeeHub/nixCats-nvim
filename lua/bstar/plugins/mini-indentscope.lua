require('mini.indentscope').setup({ symbol = "│" })

local highlight = { "Dark" }
local hooks = require "ibl.hooks"

-- create the highlight groups in the highlight setup hook, so they are reset
-- every time the colorscheme changes
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
    vim.api.nvim_set_hl(0, "Dark", { fg = "#22222B" })
    vim.api.nvim_set_hl(0, 'CurrentScope', { fg = "#33333B" })
end)
