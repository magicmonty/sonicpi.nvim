local M = {}
local uv = require('luv')

M.send_udp = function(host, port, data)
  local client = uv.new_udp()

  uv.udp_send(client, data, host, port)
end

-- makes a null padded string rounded up to the nearest
-- multiple of 4
M.encode = function(s)
  s = s .. '\0'
  local len = #s
  local pad = 4 - (len % 4)
  if pad == 4 then
    pad = 0
  end
  return s .. string.rep('\0', pad)
end

-- converts an integer into it's 32bit big endian binary representation
M.pack = function(n)
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

M.encodeMessage = function(data)
  local tags = ''
  for _, value in ipairs(data) do
    if type(value) == 'number' then
      tags = tags .. 'i'
    elseif type(value) == 'string' then
      tags = tags .. 's'
    end
  end

  if tags then
    tags = ',' .. tags
  end

  local message = ''
  for _, value in ipairs(data) do
    if type(value) == 'number' then
      message = message .. M.pack(value)
    elseif type(value) == 'string' then
      message = message .. M.encode(value)
    end
  end

  return M.encode(tags) .. message
end

M.send = function(host, port, address, message)
  M.send_udp(host, port, M.encode(address) .. M.encodeMessage(message))
end

return M
