require('rose-pine').setup({
	--- @usage 'auto'|'main'|'moon'|'dawn'
	variant = 'main',
	--- @usage 'main'|'moon'|'dawn'
	dark_variant = 'main',
	bold_vert_split = false,
	dim_nc_background = false,
	disable_background = false,
	disable_float_background = false,
	disable_italics = false,

	--- @usage string hex value or named color from rosepinetheme.com/palette
	groups = {
		background = 'base',
		background_nc = '_experimental_nc',
		panel = 'surface',
		panel_nc = 'base',
		border = 'highlight_med',
		comment = 'muted',
		link = 'iris',
		punctuation = 'subtle',

		error = 'love',
		hint = 'iris',
		info = 'foam',
		warn = 'gold',

		-- headings = {
		-- 	h1 = 'iris',
		-- 	h2 = 'foam',
		-- 	h3 = 'rose',
		-- 	h4 = 'gold',
		-- 	h5 = 'pine',
		-- 	h6 = 'foam',
		-- }
		-- or set all headings at once
		headings = 'subtle'
	},

	-- Change specific vim highlight groups
	-- https://github.com/rose-pine/neovim/wiki/Recipes
	highlight_groups = {
		ColorColumn = { bg = 'rose' },
                LineNr = { fg = '#dddddd' },
                LineNrAbove = { fg = '#403d52' },
                LineNrBelow = { fg = '#403d52' },
                Visual = { bg = '#11111B' },

		-- Blend colours against the "base" background
		CursorLine = { bg = '#000000', blend = 10 },
		-- StatusLine = { fg = 'love', bg = 'love', blend = 10 },

		-- By default each group adds to the existing config.
		-- If you only want to set what is written in this config exactly,
		-- you can set the inherit option:
		Search = { bg = 'pine', inherit = false },
	}
})

-- Set colorscheme after options
vim.cmd('colorscheme rose-pine')
