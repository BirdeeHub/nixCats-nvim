if not nixCats('general') then
  return
end
-- NOTE: Lazydev will make your Lua LSP stronger for Neovim config
-- we are also using this as an opportunity to show you how to lazy load plugins!
-- This plugin was added to the optionalPlugins section of the main nix file of this template.
-- Thus, it is not loaded and must be packadded.
-- NOTE: Use `:nixCats pawsible` to see the names of all plugins downloaded via Nix for packadd.
vim.cmd.packadd('lazydev.nvim')
require('lazydev').setup({
  library = {
    { path = nixCats.nixCatsPath and nixCats.nixCatsPath .. 'lua' or nil, words = { "nixCats" } },
  },
})
