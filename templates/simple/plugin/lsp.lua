if not nixCats('general') then
  return
end
-- NOTE: lsp setup via lspconfig

local servers = {}

-- most don't need much configuration
-- servers.gopls = {}
-- servers.html = {}

-- but you can provide some if you want to!
servers.lua_ls = {
  settings = {
    Lua = {
      formatters = {
        ignoreComments = true,
      },
      signatureHelp = { enabled = true },
      diagnostics = {
        globals = { 'vim', 'nixCats' },
        disable = { 'missing-fields' },
      },
    }
  }
}
-- nixd requires some configuration.
-- luckily, the nixCats plugin is here to pass whatever we need!
-- for additional configuration options, refer to:
-- https://github.com/nix-community/nixd/blob/main/nixd/docs/configuration.md
servers.nixd = {
  settings = {
    nixd = {
      nixpkgs = {
        -- in the extras set of your package definition:
        -- nixdExtras.nixpkgs = ''import ${pkgs.path} {}''
        expr = nixCats.extra("nixdExtras.nixpkgs") or [[import <nixpkgs> {}]],
      },
      options = {
        -- If you integrated with your system flake,
        -- you should use inputs.self as the path to your system flake
        -- that way it will ALWAYS work, regardless
        -- of where your config actually was.
        nixos = {
          -- in this package definition's.extra set
          -- nixdExtras.nixos_options = ''(builtins.getFlake "path:${builtins.toString inputs.self.outPath}").nixosConfigurations.configname.options''
          expr = nixCats.extra("nixdExtras.nixos_options")
        },
        -- If you have your config as a separate flake, inputs.self would be referring to the wrong flake.
        -- You can override the correct one into your package definition on import in your main configuration,
        -- or just put an absolute path to where it usually is and accept the impurity.
        ["home-manager"] = {
          -- nixdExtras.home_manager_options = ''(builtins.getFlake "path:${builtins.toString inputs.self.outPath}").homeConfigurations.configname.options''
          expr = nixCats.extra("nixdExtras.home_manager_options")
        }
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
}

vim.lsp.config('*', {
  -- capabilities = capabilities,
  on_attach = function(_, bufnr)
    -- we create a function that lets us more easily define mappings specific
    -- for LSP related items. It sets the mode, buffer and description for us each time.
    local nmap = function(keys, func, desc)
      if desc then
        desc = 'LSP: ' .. desc
      end
      vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
    end

    nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
    nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
    nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
    nmap('gr', function() Snacks.picker.lsp_references() end, '[G]oto [R]eferences')
    nmap('gI', function() Snacks.picker.lsp_implementations() end, '[G]oto [I]mplementation')
    nmap('<leader>ds', function() Snacks.picker.lsp_symbols() end, '[D]ocument [S]ymbols')
    nmap('<leader>ws', function() Snacks.picker.lsp_workspace_symbols() end, '[W]orkspace [S]ymbols')

    -- See `:help K` for why this keymap
    nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
    nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

    -- Lesser used LSP functionality
    nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
    nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
    nmap('<leader>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, '[W]orkspace [L]ist Folders')

    -- Create a command `:Format` local to the LSP buffer
    vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
      vim.lsp.buf.format()
    end, { desc = 'Format current buffer with LSP' })
  end,
})

-- set up the servers to be loaded on the appropriate filetypes!
for server_name, cfg in pairs(servers) do
  vim.lsp.config(server_name, cfg)
  vim.lsp.enable(server_name)
end
