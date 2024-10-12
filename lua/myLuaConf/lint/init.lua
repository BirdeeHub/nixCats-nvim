require('lze').load {
  {
    "nvim-lint",
    enabled = require('nixCatsUtils').enableForCategory('lint'),
    -- cmd = { "" },
    event = "FileType",
    -- ft = "",
    -- keys = "",
    -- colorscheme = "",
    after = function (plugin)
      require('lint').linters_by_ft = {
        -- markdown = {'vale',},
        -- javascript = { 'eslint' },
        -- typescript = { 'eslint' },
      }

      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        callback = function()
          require("lint").try_lint()
        end,
      })
    end,
  },
}
