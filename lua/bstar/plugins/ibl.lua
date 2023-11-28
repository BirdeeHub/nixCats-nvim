vim.cmd([[highlight bstarDark ctermbg=0 guifg=#22222B]])
local highlight = { "bstarDark" }

require('ibl').setup({
    indent = { highlight = highlight, char = '│' },
    scope = {
        highlight = "FloatBorder",
        show_start = true,
        show_end = false,
    },
})
