local has_remote, remote = pcall(require, 'sonicpi.remote')
if not has_remote then
  return
end
local log = require('sonicpi.log')
local map = vim.keymap.set
local default_opts = { noremap = true, silent = true, buffer = vim.api.nvim_get_current_buf() }

for _, mapping in ipairs(require('sonicpi.opts').mappings) do
  local opts = #mapping == 4 and mapping[4] or default_opts
  if #mapping == 3 or #mapping == 4 then
    map(mapping[1], mapping[2], mapping[3], opts)
  end
end

vim.api.nvim_buf_create_user_command(0, 'SonicPiStartDaemon', remote.startServer, {})
vim.api.nvim_buf_create_user_command(0, 'SonicPiStopDaemon', remote.stopServer, {})
vim.api.nvim_buf_create_user_command(0, 'SonicPiHideLogs', log.hide_logs, {})
vim.api.nvim_buf_create_user_command(0, 'SonicPiCloseLogs', log.close_logs, {})
vim.api.nvim_buf_create_user_command(0, 'SonicPiShowLogs', log.init, {})
vim.api.nvim_buf_create_user_command(0, 'SonicPiStopAndClose', function()
  log.close_logs()
  remote.stopServer()
end, {})
vim.api.nvim_buf_create_user_command(0, 'SonicPiSendBuffer', remote.run_current_buffer, {})
vim.api.nvim_buf_create_user_command(0, 'SonicPiStop', remote.stop, {})
