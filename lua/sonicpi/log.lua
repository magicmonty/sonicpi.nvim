local api = vim.api
local uv = vim.loop
local osc = require('sonicpi.osc')

local M = {}

local function setBufferOptions(name)
  local buffer = api.nvim_get_current_buf()
  api.nvim_buf_set_name(buffer, name)
  api.nvim_buf_set_option(buffer, 'swapfile', false)
  api.nvim_buf_set_option(buffer, 'filetype', 'log')
  api.nvim_buf_set_option(buffer, 'bufhidden', 'wipe')
  api.nvim_create_autocmd('QuitPre', {
    buffer = buffer,
    callback = function()
      api.nvim_buf_set_option(buffer, 'modified', false)
    end,
  })

  return { buffer = buffer, window = api.nvim_get_current_win() }
end

local function create_server(port, on_connect)
  local server = uv.new_udp()
  uv.udp_bind(server, '127.0.0.1', port)
  on_connect(server)
  return server
end

M.checkBuffers = function()
  if not api.nvim_buf_is_valid(M.log.buffer) and not api.nvim_buf_is_valid(M.cue.buffer) then
    M.stopListening()
    return false
  end

  return true
end

M.stopListening = function()
  if not M.log_server then
    return
  end

  M.log_server:recv_stop()
  M.log_server:close()
  M.log_server = nil
  vim.notify('Log listener stopped')
end

local function log_cue(message, buffer, window)
  api.nvim_buf_set_lines(buffer, -1, -1, false, { vim.inspect(message) })
  api.nvim_buf_set_option(buffer, 'modified', false)
  local line_count = api.nvim_buf_line_count(buffer)
  api.nvim_win_set_cursor(window, { line_count, 0 })
end

local function log_log(message, buffer, window)
  local log_message = #message.data == 2 and message.data[2] or nil

  if not log_message then
    return
  end

  for i, line in ipairs(vim.split(log_message, '\n')) do
    if i == 1 then
      line = '=> ' .. line
    end
    api.nvim_buf_set_lines(buffer, -1, -1, false, { line })
  end

  api.nvim_buf_set_option(buffer, 'modified', false)
  local line_count = api.nvim_buf_line_count(buffer)
  api.nvim_win_set_cursor(window, { line_count, 0 })
end

M.init = function(ports)
  if ports.gui then
    local current_window = api.nvim_get_current_win()
    vim.cmd([[ botright vsplit new ]])
    api.nvim_win_set_width(0, 80)
    M.log = setBufferOptions('SonicPi Log')

    vim.cmd([[ split new ]])
    M.cue = setBufferOptions('Cue Log')
    api.nvim_set_current_win(current_window)

    M.log_server = create_server(ports.gui, function(sock)
      sock:recv_start(function(err, chunk)
        assert(not err, err) -- Check for errors.
        vim.schedule(function()
          if not M.checkBuffers() then
            return
          end

          if chunk then
            local data = osc.decode(chunk)
            if not data then
              return
            end
            if data.address[1] == 'log' then
              log_log(data, M.log.buffer, M.log.window)
            elseif data.address[1] == 'incoming' and data.address[2] == 'osc' then
              log_cue(data.data, M.cue.buffer, M.cue.window)
            end
          end
        end)
      end)
    end)
  end
end

return M
