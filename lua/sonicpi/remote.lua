local Job = require('plenary.job')
local osc = require('sonicpi.osc')
local log = require('sonicpi.log')

local M = {}

local function parse_ports(line)
  local match = line:match('(%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (-?%d+)')
  if match then
    local daemon, spider_to_gui, gui_to_spider, scsynth, osc_cues, tau, phx, token = line:match(
      '(%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (-?%d+)'
    )

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

  return nil
end

M.send_message = function(address, message, port)
  local ports = vim.g.sonic_pi_ports

  if not ports then
    vim.notify('Unknown ports')
    return
  end

  if not port then
    port = ports.spider
  end

  osc.send('127.0.0.1', port, address, { ports.token, message })
end

M.send_token = function(address, port)
  local ports = vim.g.sonic_pi_ports

  if not ports then
    vim.notify('Unknown ports')
    return
  end

  if not port then
    port = ports.spider
  end

  osc.send('127.0.0.1', port, address, { ports.token })
end

M.run_code = function(code)
  M.send_message('/run-code', code)
end

M.run_buffer = function(bufnr)
  local current_buffer_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local current_buffer_text = table.concat(current_buffer_lines, '\n')
  M.run_code(current_buffer_text)
end

M.stop = function()
  M.send_token('/stop-all-jobs')
end

M.clear_variables = function()
  vim.schedule(function()
    vim.g.stop_sonic_pi_server = nil
    vim.g.sonic_pi_server_started = nil
    vim.g.sonic_pi_ports = nil
  end)
end

M.send_keepalive = function(port)
  if
    not vim.g.sonic_pi_server_started == 1
    or not port
    or vim.g.stop_sonic_pi_server == 1
    or not vim.g.sonic_pi_ports
  then
    vim.notify('Keep-alive stopped')
    log.stopListening()
    return
  end

  M.send_token('/daemon/keep-alive', port)

  vim.defer_fn(function()
    M.send_keepalive(port)
  end, 2000)
end

M.startServer = function()
  if vim.g.sonic_pi_server_started == 1 then
    vim.notify('Server already running')
    return
  end

  local server_dir = (vim.g.sonic_pi_opts and vim.g.sonic_pi_opts.server_dir) .. '/ruby/bin'

  if not vim.fn.isdirectory(server_dir) then
    vim.notify('Could not find server directory:\n' .. server_dir)
    return
  end

  Job
    :new({
      command = 'ruby',
      args = { 'daemon.rb' },
      cwd = server_dir,
      on_exit = function(j, return_val)
        vim.notify('SonicPi Daemon stopped with code ' .. return_val)
        M.clear_variables()
      end,
      on_stdout = function(_, data)
        if vim.g.sonic_pi_server_started == 1 then
          return
        end

        local ports = parse_ports(data)
        if ports then
          vim.schedule(function()
            log.init(ports)
          end)
          vim.g.sonic_pi_ports = ports
          vim.notify('Daemon started')
          vim.schedule(function()
            vim.g.sonic_pi_server_started = 1
            M.send_keepalive(ports.daemon)
          end)
        else
          vim.notify('Could not determine ports')
        end
      end,
    })
    :start()
end

M.sendKillswitch = function()
  if not vim.g.sonic_pi_ports then
    vim.notify('Ports not set')
    return
  end
  M.send_token('/daemon/exit', vim.g.sonic_pi_ports.daemon)
end

M.stopServer = function()
  if not vim.g.sonic_pi_server_started then
    vim.notify('Server already stopped')
    return
  end

  vim.schedule(function()
    vim.g.stop_sonic_pi_server = 1
  end)

  vim.notify('Stopping daemon ...')
  M.sendKillswitch()
end

return M
