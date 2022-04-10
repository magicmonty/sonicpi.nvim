local map = vim.keymap.set
local opts = { noremap = true, silent = true, buffer = vim.api.nvim_get_current_buf() }

map('n', '<leader>s', function()
  require('sonicpi.remote').stop()
end, opts)
map('n', '<leader>r', function()
  require('sonicpi.remote').run_buffer(vim.api.nvim_get_current_buf())
end, opts)
