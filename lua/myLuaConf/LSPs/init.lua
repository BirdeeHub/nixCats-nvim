local servers = {}
if nixCats('neonixdev') then
  -- NOTE: Lazydev will make your lua lsp stronger for neovim config
  -- NOTE: we are also using this as an opportunity to show you how to lazy load plugins!
  -- This plugin was added to the optionalPlugins section of the main flake.nix of this repo.
  -- Thus, it is not loaded and must be packadded.
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('nixCats-lazydev', { clear = true }),
    pattern = { 'lua' },
    callback = function(event)
      -- NOTE: Use `:NixCats pawsible` to see the names of all plugins downloaded via nix for packadd
      vim.cmd.packadd('lazydev.nvim')
      require('lazydev').setup({
        library = {
        --   -- See the configuration section for more details
        --   -- Load luvit types when the `vim.uv` word is found
        --   -- { path = "luvit-meta/library", words = { "vim%.uv" } },
          -- adds type hints for nixCats global
          { path = require('nixCats').nixCatsPath .. '/lua', words = { "nixCats" } },
        },
      })
    end
  })
  -- NOTE: use BirdeeHub/lze to manage the autocommands for you if the above seems tedious.
  -- Or, use the wrapper for lazy.nvim included in the luaUtils template.
  -- NOTE: AFTER DIRECTORIES WILL NOT BE SOURCED BY PACKADD!!!!!
  -- this must be done by you manually if,
  -- for example, you wanted to lazy load nvim-cmp sources

  servers.lua_ls = {
    Lua = {
      formatters = {
        ignoreComments = true,
      },
      signatureHelp = { enabled = true },
      diagnostics = {
        globals = { 'nixCats' },
        disable = { 'missing-fields' },
      },
    },
    telemetry = { enabled = false },
    filetypes = { 'lua' },
  }
  if require('nixCatsUtils').isNixCats then
    servers.nixd = {
      nixd = {
        nixpkgs = {
          -- nixd requires some configuration in flake based configs.
          -- luckily, the nixCats plugin is here to pass whatever we need!
          expr = [[import (builtins.getFlake "]] .. nixCats("nixdExtras.nixpkgs") .. [[") { }   ]],
        },
        formatting = {
          command = { "nixfmt" }
        },
        diagnostic = {
          suppress = {
            "sema-escaping-with"
          }
        }
      }
    }
    -- If you integrated with your system flake,
    -- you should pass inputs.self.outPath as nixdExtras.flake-path
    -- that way it will ALWAYS work, regardless
    -- of where your config actually was.
    -- otherwise flake-path could be an absolute path to your system flake, or nil or false
    if nixCats("nixdExtras.flake-path") and nixCats("nixdExtras.systemCFGname") and nixCats("nixdExtras.homeCFGname") then
      servers.nixd.nixd.options = {
        -- (builtins.getFlake "<path_to_system_flake>").nixosConfigurations."<name>".options
        nixos = {
          expr = [[(builtins.getFlake "]] ..
            nixCats("nixdExtras.flake-path") ..  [[").nixosConfigurations."]] ..
            nixCats("nixdExtras.systemCFGname") .. [[".options]]
        },
        -- (builtins.getFlake "<path_to_system_flake>").homeConfigurations."<name>".options
        ["home-manager"] = {
          expr = [[(builtins.getFlake "]] ..
            nixCats("nixdExtras.flake-path") .. [[").homeConfigurations."]] ..
            nixCats("nixdExtras.homeCFGname") .. [[".options]]
        }
      }
    end
  else
    servers.rnix = {}
    servers.nil_ls = {}
  end

end

-- This is this flake's version of what kickstarter has set up for mason handlers.
-- This is a convenience function that calls lspconfig on the lsps we downloaded via nix
-- This will not download your lsp. Nix does that.

--  Add any additional override configuration in the following tables. They will be passed to
--  the `settings` field of the server config. You must look up that documentation yourself.
--  All of them are listed in https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
--
--  If you want to override the default filetypes that your language server will attach to you can
--  define the property 'filetypes' to the map in question.
--  You may do the same thing with cmd

-- servers.clangd = {},
-- servers.gopls = {},
-- servers.pyright = {},
-- servers.rust_analyzer = {},
-- servers.tsserver = {},
-- servers.html = { filetypes = { 'html', 'twig', 'hbs'} },


if not require('nixCatsUtils').isNixCats and nixCats('lspDebugMode') then
  vim.lsp.set_log_level("debug")
end
-- If you were to comment out this autocommand
-- and instead pass the on attach function directly to
-- nvim-lspconfig, it would do the same thing.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('nixCats-lsp-attach', { clear = true }),
  callback = function(event)
    require('myLuaConf.LSPs.caps-on_attach').on_attach(vim.lsp.get_client_by_id(event.data.client_id), event.buf)
  end
})

if require('nixCatsUtils').isNixCats then
  for server_name, cfg in pairs(servers) do
    require('lspconfig')[server_name].setup({
      capabilities = require('myLuaConf.LSPs.caps-on_attach').get_capabilities(server_name),
      -- this line is interchangeable with the above LspAttach autocommand
      -- on_attach = require('myLuaConf.LSPs.caps-on_attach').on_attach,
      settings = cfg,
      filetypes = (cfg or {}).filetypes,
      cmd = (cfg or {}).cmd,
      root_pattern = (cfg or {}).root_pattern,
    })
  end
else
  require('mason').setup()
  local mason_lspconfig = require 'mason-lspconfig'
  mason_lspconfig.setup {
    ensure_installed = vim.tbl_keys(servers),
  }
  mason_lspconfig.setup_handlers {
    function(server_name)
      require('lspconfig')[server_name].setup {
        capabilities = require('myLuaConf.LSPs.caps-on_attach').get_capabilities(server_name),
        -- this line is interchangeable with the above LspAttach autocommand
        -- on_attach = require('myLuaConf.LSPs.caps-on_attach').on_attach,
        settings = servers[server_name],
        filetypes = (servers[server_name] or {}).filetypes,
      }
    end,
  }
end
