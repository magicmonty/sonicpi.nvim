local M = {}
local function get_ports()
  if M.ports then
    return M.ports
  end
  local lines = io.lines(vim.fn.expand('~/.sonic-pi/log/daemon.log'))

  for line in lines do
    local match = line:match('(%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (-?%d+)')
    if match then
      local daemon, spider_to_gui, gui_to_spider, scsynth, osc_cues, tau, phx, token = line:match(
        '(%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (-?%d+)'
      )

      M.ports = {
        daemon = tonumber(daemon),
        gui = tonumber(spider_to_gui),
        spider = tonumber(gui_to_spider),
        scsynth = tonumber(scsynth),
        osc_cues = tonumber(osc_cues),
        tau = tonumber(tau),
        phx = tonumber(phx),
        token = tonumber(token),
      }

      break
    end
  end

  return M.ports
end

-- makes a null padded string rounded up to the nearest
-- multiple of 4
local function encode(s)
  local len = #s
  local pad = 4 - (len % 4)
  if pad == 4 then
    pad = 0
  end
  return s .. string.rep('\0', pad)
end

-- converts an integer into it's 32bit big endian binary representation
local function pack(n)
  if n > 2147483647 then
    error(n .. ' is too large', 2)
  end
  if n < -2147483648 then
    error(n .. ' is too small', 2)
  end
  -- adjust for 2's complement
  n = (n < 0) and (4294967296 + n) or n
  return string.char(unpack({
    (math.modf(n / 16777216)) % 256,
    (math.modf(n / 65536)) % 256,
    (math.modf(n / 256)) % 256,
    n % 256,
  }))
end

local function send_osc(address, message)
  local ports = get_ports()

  address = encode(address)
  if message then
    message = encode(message)
  end

  local tags = message and encode(',is') or encode(',i')

  local token = pack(ports.token)

  local uv = require('luv')
  local host = '127.0.0.1'
  local client = uv.new_udp()

  local send_data = message and address .. tags .. token .. message or address .. tags .. token

  uv.udp_send(client, send_data, host, ports.spider)
end

M.run_code = function(code)
  send_osc('/run-code', code)
end

M.run_buffer = function(bufnr)
  local current_buffer_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local current_buffer_text = table.concat(current_buffer_lines, '\n')
  M.run_code(current_buffer_text)
end

M.stop = function()
  send_osc('/stop-all-jobs')
end

return M
