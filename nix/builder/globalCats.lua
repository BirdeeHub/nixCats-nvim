vim.api.nvim_create_user_command('NixCats',
[[lua print(vim.inspect(require('nixCats.cats')))]] ,
{ desc = 'So Cute!' })

require('_G').nixCats = require('nixCats').get
