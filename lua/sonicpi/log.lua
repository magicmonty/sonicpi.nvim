local api = vim.api
local uv = vim.loop
local osc = require('sonicpi.osc')

local M = {}

local function replace_buffer(buffer)
  local tempBuffer = api.nvim_get_current_buf()
  local window = api.nvim_get_current_win()
  api.nvim_win_set_buf(window, buffer)
  api.nvim_buf_delete(tempBuffer, { force = true })
  return { buffer = buffer, window = window }
end

local function set_buffer_options(name)
  local tempBuffer = api.nvim_get_current_buf()
  local buffer = api.nvim_create_buf(false, true)
  local window = api.nvim_get_current_win()
  api.nvim_win_set_buf(window, buffer)
  api.nvim_buf_delete(tempBuffer, { force = true })

  api.nvim_buf_set_name(buffer, name)
  api.nvim_buf_set_option(buffer, 'swapfile', false)
  api.nvim_buf_set_option(buffer, 'filetype', 'log')
  -- api.nvim_buf_set_option(buffer, 'bufhidden', 'wipe')
  api.nvim_create_autocmd('QuitPre', {
    buffer = buffer,
    callback = function()
      api.nvim_buf_set_option(buffer, 'modified', false)
    end,
  })

  return { buffer = buffer, window = window }
end

local function create_server(port, on_connect)
  local server = uv.new_udp()
  uv.udp_bind(server, '0.0.0.0', port)
  on_connect(server)
  return server
end

M.check_buffers = function()
  if not api.nvim_buf_is_valid(M.log.buffer) and not api.nvim_buf_is_valid(M.cue.buffer) then
    M.stop_listening()
    return false
  end

  return true
end

M.stop_listening = function()
  if not M.log_server then
    return
  end

  M.log_server:recv_stop()
  M.log_server:close()
  M.log_server = nil
end

local function log_cue(message, config)
  local buffer = config and config.buffer or nil
  local window = config and config.window or nil
  if not buffer or not api.nvim_buf_is_valid(buffer) then
    return
  end

  local command = message[3]
  local params = message[4]

  api.nvim_buf_set_lines(buffer, -1, -1, false, { command .. '  ' .. params })
  local line_count = api.nvim_buf_line_count(buffer)
  api.nvim_buf_add_highlight(buffer, -1, 'SonicPiCueName', line_count - 1, 0, #command)
  api.nvim_buf_add_highlight(buffer, -1, 'SonicPiCueValue', line_count - 1, #command + 2, -1)

  api.nvim_buf_set_option(buffer, 'modified', false)

  if window and api.nvim_win_is_valid(window) then
    api.nvim_win_set_cursor(window, { line_count, 0 })
  end
end

local function log_log(message, config)
  local buffer = config and config.buffer or nil
  local window = config and config.window or nil
  if not buffer or not api.nvim_buf_is_valid(buffer) then
    return
  end

  local log_message = ''
  local style = 0
  local is_multi_message = false

  if message.address[2] == 'multi_message' then
    local run = message.data[1]
    local time = message.data[3]
    local thread = message.data[2]
    local synth = message.data[6]

    log_message = '{run: ' .. run .. ', time: ' .. time .. ', thread: ' .. thread .. '}\n└─ ' .. synth
    is_multi_message = true
    style = 0
  elseif #message.data == 2 then
    style = message.data[1]
    log_message = message.data[2]
  else
    vim.notify(vim.inspect(message))
    return
  end

  if not log_message then
    return
  end

  local log_line_count = 0
  for i, line in ipairs(vim.split(log_message .. '\n', '\n')) do
    log_line_count = log_line_count + 1
    if i == 1 and not is_multi_message then
      line = '=> ' .. line
    end
    api.nvim_buf_set_lines(buffer, -1, -1, false, { line })
    if style == 1 then
      api.nvim_buf_add_highlight(buffer, -1, 'SonicPiLogMessageAlternate', api.nvim_buf_line_count(buffer) - 1, 0, -1)
    else
      api.nvim_buf_add_highlight(buffer, -1, 'SonicPiLogMessage', api.nvim_buf_line_count(buffer) - 1, 0, -1)
    end
  end

  api.nvim_buf_set_option(buffer, 'modified', false)
  if window and api.nvim_win_is_valid(window) then
    local line_count = api.nvim_buf_line_count(buffer)
    api.nvim_win_set_cursor(window, { line_count, 0 })
  end
end

local function log_other(message, config)
  local buffer = config and config.buffer or nil
  local window = config and config.window or nil
  if not buffer or not api.nvim_buf_is_valid(buffer) then
    return
  end

  if message.address_raw == '/exited' then
    api.nvim_buf_set_lines(buffer, -1, -1, false, { '=> Daemon stopped' })
    api.nvim_buf_add_highlight(buffer, -1, 'SonicPiLogMessageAlternate', api.nvim_buf_line_count(buffer) - 1, 0, -1)
  else
    return
  end

  api.nvim_buf_set_option(buffer, 'modified', false)
  if window and api.nvim_win_is_valid(window) then
    local line_count = api.nvim_buf_line_count(buffer)
    api.nvim_win_set_cursor(window, { line_count, 0 })
  end
end

local function close_log_window(config, force)
  if not config then
    return nil
  end

  local buffer = config.buffer
  local window = config.window

  if window and api.nvim_win_is_valid(window) then
    api.nvim_win_close(window, true)
    config.window = nil
  end

  if force then
    if buffer and api.nvim_buf_is_valid(buffer) then
      api.nvim_buf_delete(buffer, { force = true })
    end
    config = nil
  end

  return config
end

M.close_logs = function(force)
  if M.log then
    M.log = close_log_window(M.log, force)
  end

  if M.cue then
    M.cue = close_log_window(M.cue, force)
  end

  if not M.log and not M.cue then
    M.stop_listening()
  end
end

M.force_log_window = function()
  local current_window = api.nvim_get_current_win()
  local current_width = api.nvim_win_get_width(current_window)
  local util_window_width = math.max(57, math.floor(current_width / 4))

  local split_top = function()
    api.nvim_set_current_win(M.cue.window)
    vim.cmd([[ topleft split new ]])
    if M.log and M.log.buffer and api.nvim_buf_is_valid(M.log.buffer) then
      return replace_buffer(M.log.buffer)
    else
      return set_buffer_options('SonicPi Log')
    end
  end

  local split_right = function()
    vim.cmd([[ botright vsplit new ]])
    api.nvim_win_set_width(0, util_window_width)
    if M.log and M.log.buffer and api.nvim_buf_is_valid(M.log.buffer) then
      return replace_buffer(M.log.buffer)
    else
      return set_buffer_options('SonicPi Log')
    end
  end

  if M.log then
    if M.log.window and api.nvim_win_is_valid(M.log.window) then
      local window_buffer = api.nvim_win_get_buf(M.log.window)
      if window_buffer == M.log.buffer then
        -- settings still correct --> Do nothing
      elseif api.nvim_buf_is_valid(M.log.buffer) then
        -- if buffer has changed in log window, but it is still active
        -- then set the buffer of the log window to the configured one
        api.nvim_win_set_buf(M.log.window, M.log.buffer)
      end
    else
      if M.cue and M.cue.window and api.nvim_win_is_valid(M.cue.window) then
        -- cue log still exists --> go to cue log and split to the top
        M.log = split_top()
      else
        -- cue log does not exist --> split to the right
        M.log = split_right()
      end
    end
  else
    if not M.cue or (M.cue and not M.cue.window) then
      -- cue log does not exist --> split to the right
      M.log = split_right()
    else
      -- cue log still exists --> go to cue log and split to the top
      M.log = split_top()
    end
  end

  api.nvim_set_current_win(current_window)
end

M.force_cue_window = function()
  local current_window = api.nvim_get_current_win()
  local current_width = api.nvim_win_get_width(current_window)
  local util_window_width = math.max(57, math.floor(current_width / 4))

  local split_bottom = function()
    api.nvim_set_current_win(M.log.window)
    vim.cmd([[ split new ]])
    if M.cue and M.cue.buffer and api.nvim_buf_is_valid(M.cue.buffer) then
      return replace_buffer(M.cue.buffer)
    else
      return set_buffer_options('Cue Log')
    end
  end

  local split_right = function()
    vim.cmd([[ botright vsplit new ]])
    api.nvim_win_set_width(0, util_window_width)
    if M.cue and M.cue.buffer and api.nvim_buf_is_valid(M.cue.buffer) then
      return replace_buffer(M.cue.buffer)
    else
      return set_buffer_options('Cue Log')
    end
  end

  if M.cue then
    if M.cue.window and api.nvim_win_is_valid(M.cue.window) then
      local window_buffer = api.nvim_win_get_buf(M.cue.window)
      if window_buffer == M.cue.buffer then
        -- settings still correct --> Do nothing
      elseif api.nvim_buf_is_valid(M.cue.buffer) then
        -- if buffer has changed in cue window, but it is still active
        -- then set the buffer of the cue window to the configured one
        api.nvim_win_set_buf(M.cue.window, M.cue.buffer)
      end
    else
      if M.log and M.log.window and api.nvim_win_is_valid(M.log.window) then
        -- log window still exists --> go to log and split to the bottom
        M.cue = split_bottom()
      else
        -- log window does not exist --> split to the right
        M.cue = split_right()
      end
    end
  else
    if not M.log or (M.log and not M.log.window) then
      -- log window does not exist --> split to the right
      M.cue = split_right()
    else
      -- log window still exists --> go to log and split to the bottom
      M.cue = split_bottom()
    end
  end

  api.nvim_set_current_win(current_window)
end

M.init = function(ports)
  if ports.gui then
    M.force_log_window()
    M.force_cue_window()

    if not M.log_server then
      M.log_server = create_server(ports.gui, function(sock)
        sock:recv_start(function(err, chunk)
          assert(not err, err) -- Check for errors.
          vim.schedule(function()
            if not M.check_buffers() then
              return
            end
            if chunk then
              local data = osc.decode(chunk)
              if data.address[1] == 'log' then
                log_log(data, M.log)
              elseif data.address[1] == 'incoming' and data.address[2] == 'osc' then
                log_cue(data.data, M.cue)
              else
                log_other(data, M.log)
              end
            end
          end)
        end)
      end)
    end
  end
end

return M
