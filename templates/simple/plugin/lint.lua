if not nixCats('general') then
  return
end

require('lint').linters_by_ft = {
  -- NOTE: download some linters in lspsAndRuntimeDeps
  -- and configure them here
  -- markdown = {'vale',},
  -- javascript = { 'eslint' },
  -- typescript = { 'eslint' },
}

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  callback = function()
    require("lint").try_lint()
  end,
})
