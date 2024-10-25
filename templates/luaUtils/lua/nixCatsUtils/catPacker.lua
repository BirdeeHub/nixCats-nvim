local M = {}
-- it literally just only runs it when not on nixCats
-- all neovim package managers that use the regular plugin loading scheme
-- can be used this way, just do whatever the plugin manager needs to put it in the
-- opt directory for lazy loading, and add the build steps so that when theres no nix the steps are ran
function M.setup(v)
  if not require('nixCatsUtils').isNixCats then

    local function bootstrap_pckr()
      local pckr_path = vim.fn.stdpath("data") .. "/pckr/pckr.nvim"

      if not vim.loop.fs_stat(pckr_path) then
        vim.fn.system({
          'git',
          'clone',
          "--filter=blob:none",
          'https://github.com/lewis6991/pckr.nvim',
          pckr_path
        })
      end

      vim.opt.rtp:prepend(pckr_path)
    end

    bootstrap_pckr()

    require('pckr').add(v)
  end
end
return M
