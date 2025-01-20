--[[
  This directory is the luaUtils template.
  You can choose what things from it that you would like to use.
  And then delete the rest.
  Everything in this directory is optional.
--]]

local M = {}
-- NOTE: If you don't use lazy.nvim, you don't need this file.

---lazy.nvim wrapper
---@overload fun(nixLazyPath: string|nil, lazySpec: any, opts: table)
---@overload fun(nixLazyPath: string|nil, opts: table)
function M.setup(nixLazyPath, lazySpec, opts)
  local lazySpecs = nil
  local lazyCFG = nil
  if opts == nil and type(lazySpec) == "table" and lazySpec.spec then
    lazyCFG = lazySpec
  else
    lazySpecs = lazySpec
    lazyCFG = opts
  end

  local function regularLazyDownload()
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.loop.fs_stat(lazypath) then
      vim.fn.system {
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable', -- latest stable release
        lazypath,
      }
    end
    return lazypath
  end

  local isNixCats = vim.g[ [[nixCats-special-rtp-entry-nixCats]] ] ~= nil
  local lazypath
  if not isNixCats then
    -- No nixCats? Not nix. Do it normally
    lazypath = regularLazyDownload()
    vim.opt.rtp:prepend(lazypath)
  else
    local nixCats = require('nixCats')
    -- Else, its nix, so we wrap lazy with a few extra config options
    lazypath = nixLazyPath
    -- and also we probably dont have to download lazy either
    if lazypath == nil then
      lazypath = regularLazyDownload()
    end

    local oldPath
    local lazypatterns
    local fallback
    if type(lazyCFG) == "table" and type(lazyCFG.dev) == "table" then
      lazypatterns = lazyCFG.dev.patterns
      fallback = lazyCFG.dev.fallback
      oldPath = lazyCFG.dev.path
    end

    local myNeovimPackages = nixCats.vimPackDir .. "/pack/myNeovimPackages"

    local newLazyOpts = {
      performance = {
        rtp = {
          reset = false,
        },
      },
      dev = {
        path = function(plugin)
          local path = nil
          if type(oldPath) == "string" and vim.fn.isdirectory(oldPath .. "/" .. plugin.name) == 1 then
            path = oldPath .. "/" .. plugin.name
          elseif type(oldPath) == "function" then
            path = oldPath(plugin)
            if type(path) ~= "string" then
              path = nil
            end
          end
          if path == nil then
            if vim.fn.isdirectory(myNeovimPackages .. "/start/" .. plugin.name) == 1 then
              path = myNeovimPackages .. "/start/" .. plugin.name
            elseif vim.fn.isdirectory(myNeovimPackages .. "/opt/" .. plugin.name) == 1 then
              path = myNeovimPackages .. "/opt/" .. plugin.name
            else
              path = "~/projects/" .. plugin.name
            end
          end
          return path
        end,
        patterns = lazypatterns or { "" },
        fallback = fallback == nil and true or fallback,
      }
    }
    lazyCFG = vim.tbl_deep_extend("force", lazyCFG or {}, newLazyOpts)
    -- do the reset we disabled without removing important stuff
    local cfgdir = nixCats.configDir
    vim.opt.rtp = {
      cfgdir,
      nixCats.nixCatsPath,
      nixCats.pawsible.allPlugins.ts_grammar_path,
      vim.fn.stdpath("data") .. "/site",
      lazypath,
      vim.env.VIMRUNTIME,
      vim.fn.fnamemodify(vim.v.progpath, ":p:h:h") .. "/lib/nvim",
      cfgdir .. "/after",
    }
  end

  if lazySpecs then
    require('lazy').setup(lazySpecs, lazyCFG)
  else
    require('lazy').setup(lazyCFG)
  end
end

return M
