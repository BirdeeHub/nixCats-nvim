local M = {}
  -- first you should go ahead and install your dependencies
  -- you arent using nix if you are using this.
  -- this means you will have to install some stuff manually.

  -- so, you will need cmake, gcc, npm, nodejs,
  -- ripgrep, fd, <curl or wget>, and git,
  -- you will also need rustup and to run rustup toolchain install stable

  -- now you see why nix is so great. You dont have to do that every time.

  -- so, now for the stuff we can still auto install without nix:
  -- first check if we should be loading pckr:
function M.setup(v)
  if not require('nixCatsUtils').isNixCats then
    -- you can use this same method
    -- if you want to install via mason when not in nix
    -- or just, anything you want to do only when not using nix

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
