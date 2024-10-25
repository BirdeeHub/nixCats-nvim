local M = {}
-- it literally just only runs it when not on nixCats
-- all neovim package managers that use the regular plugin loading scheme
-- can be used this way, just do whatever the plugin manager needs to put it in the
-- opt directory for lazy loading, and add the build steps so that when theres no nix the steps are ran
function M.setup(v)
  if not require('nixCatsUtils').isNixCats then
    local function bootstrap_paq()
      local paq_path = vim.fn.stdpath("data") .. "/site/pack/paqs/start/paq-nvim"

      if not vim.loop.fs_stat(paq_path) then
        vim.fn.system({ "git", "clone", "--depth=1", "https://github.com/savq/paq-nvim.git", paq_path })
      end

      vim.opt.rtp:prepend(paq_path)
    end

    bootstrap_paq()
    vim.cmd.packadd("paq-nvim")
    local paq = require("paq")
    paq(v)
    paq.install()
  end
end
return M
