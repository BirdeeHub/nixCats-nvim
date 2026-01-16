if not nixCats('general') then
  return
end

-- https://github.com/nvim-treesitter/nvim-treesitter-textobjects/tree/main?tab=readme-ov-file#using-a-package-manager
-- Disable entire built-in ftplugin mappings to avoid conflicts.
-- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
vim.g.no_plugin_maps = true

-- Or, disable per filetype (add as you like)
-- vim.g.no_python_maps = true
-- vim.g.no_ruby_maps = true
-- vim.g.no_rust_maps = true
-- vim.g.no_go_maps = true

---@param buf integer
---@param language string
local function treesitter_try_attach(buf, language)
  -- check if parser exists and load it
  if not vim.treesitter.language.add(language) then
    return false
  end
  -- enables syntax highlighting and other treesitter features
  vim.treesitter.start(buf, language)

  -- enables treesitter based folds
  vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

  -- enables treesitter based indentation
  vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

  return true
end

local installable_parsers = require("nvim-treesitter").get_available()
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local buf, filetype = args.buf, args.match
    local language = vim.treesitter.language.get_lang(filetype)
    if not language then
      return
    end

    if not treesitter_try_attach(buf,language) then
      if vim.tbl_contains(installable_parsers, language) then
        -- not already installed, so try to install them via nvim-treesitter if possible
        require("nvim-treesitter").install(language):await(function()
          treesitter_try_attach(buf, language)
        end)
      end
    end
  end,
})

require("nvim-treesitter-textobjects").setup {
  select = {
    -- Automatically jump forward to textobj, similar to targets.vim
    lookahead = true,
    -- You can choose the select mode (default is charwise 'v')
    --
    -- Can also be a function which gets passed a table with the keys
    -- * query_string: eg '@function.inner'
    -- * method: eg 'v' or 'o'
    -- and should return the mode ('v', 'V', or '<c-v>') or a table
    -- mapping query_strings to modes.
    selection_modes = {
      ['@parameter.outer'] = 'v', -- charwise
      ['@function.outer'] = 'V', -- linewise
      -- ['@class.outer'] = '<c-v>', -- blockwise
    },
    -- If you set this to `true` (default is `false`) then any textobject is
    -- extended to include preceding or succeeding whitespace. Succeeding
    -- whitespace has priority in order to act similarly to eg the built-in
    -- `ap`.
    --
    -- Can also be a function which gets passed a table with the keys
    -- * query_string: eg '@function.inner'
    -- * selection_mode: eg 'v'
    -- and should return true of false
    include_surrounding_whitespace = false,
  },
}

-- keymaps
-- You can use the capture groups defined in `textobjects.scm`
vim.keymap.set({ "x", "o" }, "am", function()
  require "nvim-treesitter-textobjects.select".select_textobject("@function.outer", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "im", function()
  require "nvim-treesitter-textobjects.select".select_textobject("@function.inner", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "ac", function()
  require "nvim-treesitter-textobjects.select".select_textobject("@class.outer", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "ic", function()
  require "nvim-treesitter-textobjects.select".select_textobject("@class.inner", "textobjects")
end)
-- You can also use captures from other query groups like `locals.scm`
vim.keymap.set({ "x", "o" }, "as", function()
  require "nvim-treesitter-textobjects.select".select_textobject("@local.scope", "locals")
end)

-- NOTE: for more textobjects options, see the following link.
-- This template is using the new `main` branch of the repo.
-- https://github.com/nvim-treesitter/nvim-treesitter-textobjects/tree/main
