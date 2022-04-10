local M = {}

M.send_buffer = function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local buffer = '"' .. table.concat(lines, '\n') .. '"'
  vim.fn.system('oscsend localhost 32283 /run-code is 1164618348 ' .. buffer)
end

M.stop = function() end

return M
