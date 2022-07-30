local Job = require('plenary.job')
local osc = require('sonicpi.osc')
local log = require('sonicpi.log')

local M = {}

local empty_ports = {
  daemon = nil,
  gui = nil,
  osc_cues = nil,
  phx = nil,
  sc_synth = nil,
  spider = nil,
  token = nil,
}

local function parse_ports(line)
  local match = line:match('(%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (-?%d+)')
  if match then
    local daemon, spider_to_gui, gui_to_spider, scsynth, osc_cues, tau, phx, token =
    line:match('(%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (-?%d+)')

    return {
      daemon = tonumber(daemon),
      gui = tonumber(spider_to_gui),
      spider = tonumber(gui_to_spider),
      scsynth = tonumber(scsynth),
      osc_cues = tonumber(osc_cues),
      tau = tonumber(tau),
      phx = tonumber(phx),
      token = tonumber(token),
    }
  end

  return empty_ports
end

M.send_message = function(address, message, port)
  local ports = require('sonicpi.opts').remote.ports

  if not ports.spider then
    return
  end

  if not port then
    port = ports.spider
  end

  osc.send('127.0.0.1', port, address, { ports.token, message })
end

M.send_token = function(address, port)
  local ports = require('sonicpi.opts').remote.ports

  if not port or not ports.token then
    return
  end

  osc.send('127.0.0.1', port, address, { ports.token })
end

M.run_code = function(code)
  M.send_message('/run-code', code)
end

M.run_current_buffer = function()
  M.run_buffer(vim.api.nvim_get_current_buf())
end

M.run_buffer = function(bufnr)
  local current_buffer_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local current_buffer_text = table.concat(current_buffer_lines, '\n')
  M.run_code(current_buffer_text)
end

M.stop = function()
  M.send_message('/stop-all-jobs')
end

M.clear_variables = function()
  local opts = require('sonicpi.opts').remote
  opts.lifecycle.stop_daemon = 0
  opts.lifecycle.daemon_started = 0
  opts.ports = empty_ports
end

M.send_keepalive = function()
  local opts = require('sonicpi.opts').remote

  if opts.lifecycle.daemon_started ~= 1
      or not opts.ports.daemon
      or opts.lifecycle.stop_daemon == 1
      or not opts.ports.token
      or not opts.ports.spider
  then
    log.stop_listening()
    return
  end

  M.send_token('/daemon/keep-alive', opts.ports.daemon)

  vim.defer_fn(function()
    M.send_keepalive()
  end, 2000)
end

M.startServer = function()
  local opts = require('sonicpi.opts')
  if opts.remote.lifecycle.daemon_started == 1 then
    return
  end

  local server_dir = opts.server_dir .. '/ruby/bin'

  if not vim.fn.isdirectory(server_dir) then
    vim.notify('Could not find server directory:\n' .. server_dir)
    return
  end

  Job:new({
    command = 'ruby',
    args = { 'daemon.rb' },
    cwd = server_dir,
    on_exit = function(_, return_val)
      vim.notify('SonicPi Daemon stopped with code ' .. return_val)
      M.clear_variables()
    end,
    on_stdout = function(_, data)
      if require('sonicpi.opts').remote.lifecycle.daemon_started == 1 then
        return
      end

      local ports = parse_ports(data)
      if ports.gui and ports.daemon and ports.token and ports.spider then
        vim.schedule(function()
          require('sonicpi.opts').remote.ports = ports
          log.init()
        end)

        vim.schedule(function()
          require('sonicpi.opts').remote.lifecycle.daemon_started = 1
          M.send_keepalive()
        end)
      else
        vim.notify('Could not determine ports')
      end
    end,
  }):start()
end

M.sendKillswitch = function()
  local port = require('sonicpi.opts').remote.ports.daemon
  if not port then
    return
  end
  M.send_token('/daemon/exit', port)
end

M.stopServer = function()
  local opts = require('sonicpi.opts').remote
  if opts.lifecycle.daemon_started ~= 1 then
    return
  end

  opts.lifecycle.stop_daemon = 1

  M.sendKillswitch()
end

return M
