require('lze').load {
  "nvim-dap",
  enabled = require('nixCatsUtils').enableForCategory('debug'),
  -- cmd = { "" },
  -- event = "",
  -- ft = "",
  keys = {
    { "<F5>", desc = "Debug: Start/Continue" },
    { "<F1>", desc = "Debug: Step Into" },
    { "<F2>", desc = "Debug: Step Over" },
    { "<F3>", desc = "Debug: Step Out" },
    { "<leader>b", desc = "Debug: Toggle Breakpoint" },
    { "<leader>B", desc = "Debug: Set Breakpoint" },
    { "<F7>", desc = "Debug: See last session result." },
  },
  -- colorscheme = "",
  load = (require('nixCatsUtils').isNixCats and function(name)
    vim.cmd.packadd(name)
    vim.cmd.packadd("nvim-dap-ui")
    vim.cmd.packadd("nvim-dap-virtual-text")
  end) or function(name)
    vim.cmd.packadd(name)
    vim.cmd.packadd("nvim-dap-ui")
    vim.cmd.packadd("nvim-dap-virtual-text")
    vim.cmd.packadd("mason-nvim-dap.nvim")
  end,
  after = function (plugin)
    local dap = require 'dap'
    local dapui = require 'dapui'

    -- Basic debugging keymaps, feel free to change to your liking!
    vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', '<F1>', dap.step_into, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', '<F2>', dap.step_over, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', '<F3>', dap.step_out, { desc = 'Debug: Step Out' })
    vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
    vim.keymap.set('n', '<leader>B', function()
      dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
    end, { desc = 'Debug: Set Breakpoint' })

    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    require("nvim-dap-virtual-text").setup {
      enabled = true,                       -- enable this plugin (the default)
      enabled_commands = true,              -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
      highlight_changed_variables = true,   -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
      highlight_new_as_changed = false,     -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
      show_stop_reason = true,              -- show stop reason when stopped for exceptions
      commented = false,                    -- prefix virtual text with comment string
      only_first_definition = true,         -- only show virtual text at first definition (if there are multiple)
      all_references = false,               -- show virtual text on all all references of the variable (not only definitions)
      clear_on_continue = false,            -- clear virtual text on "continue" (might cause flickering when stepping)
      --- A callback that determines how a variable is displayed or whether it should be omitted
      --- variable Variable https://microsoft.github.io/debug-adapter-protocol/specification#Types_Variable
      --- buf number
      --- stackframe dap.StackFrame https://microsoft.github.io/debug-adapter-protocol/specification#Types_StackFrame
      --- node userdata tree-sitter node identified as variable definition of reference (see `:h tsnode`)
      --- options nvim_dap_virtual_text_options Current options for nvim-dap-virtual-text
      --- string|nil A text how the virtual text should be displayed or nil, if this variable shouldn't be displayed
      display_callback = function(variable, buf, stackframe, node, options)
        if options.virt_text_pos == 'inline' then
          return ' = ' .. variable.value
        else
          return variable.name .. ' = ' .. variable.value
        end
      end,
      -- position of virtual text, see `:h nvim_buf_set_extmark()`, default tries to inline the virtual text. Use 'eol' to set to end of line
      virt_text_pos = vim.fn.has 'nvim-0.10' == 1 and 'inline' or 'eol',

      -- experimental features:
      all_frames = false,       -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
      virt_lines = false,       -- show virtual lines instead of virtual text (will flicker!)
      virt_text_win_col = nil   -- position the virtual text at a fixed window column (starting from the first text column) ,
      -- e.g. 80 to position at column 80, see `:h nvim_buf_set_extmark()`
    }

    -- NOTE: Install lang specific config
    -- if nixCats('go') then
    --   require('dap-go').setup()
    -- end

  end,
}
