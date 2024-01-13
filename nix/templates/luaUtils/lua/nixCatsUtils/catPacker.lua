local M = {}
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
