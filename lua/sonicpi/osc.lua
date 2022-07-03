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

local function read_string(bytes)
  if not bytes then
    return nil, nil
  end

  local result = ''
  local is_rest = false
  local rest = {}
  local count = #bytes

  for i = 1, count, 1 do
    local byte = bytes[i]
    if is_rest then
      table.insert(rest, byte)
    elseif byte > 0 then
      result = result .. string.char(byte)
    elseif i % 4 == 0 then
      is_rest = true
    end
  end

  return result, rest
end

local function read_int(bytes)
  if not bytes then
    return nil, nil
  end
  local count = #bytes
  if count < 4 then
    return nil, nil
  end

  local b = { bytes[1] * 16777216, bytes[2] * 65536, bytes[3] * 256, bytes[4] }
  local result = b[1] + b[2] + b[3] + b[4]
  -- int is negative if bigger then 2147647
  result = result < 21474648 and result or (result - 4294967296)
  local rest = {}
  if count > 4 then
    for i = 5, #bytes, 1 do
      table.insert(rest, bytes[i])
    end
  end
  return result, rest
end

local function read_float(bytes)
  if not bytes then
    return nil, nil
  end
  local count = #bytes
  if count < 4 then
    return nil, nil
  end

  local result = 0.0
  local b = { bytes[4], bytes[3], bytes[2], bytes[1] }
  local sign = 1
  local mantissa = b[3] % 128
  for i = 2, 1, -1 do
    mantissa = mantissa * 256 + b[i]
  end
  if b[4] > 127 then
    sign = -1
  end
  local exponent = (b[4] % 128) * 2 + math.floor(b[3] / 128)
  if exponent ~= 0 then
    mantissa = (math.ldexp(mantissa, -23) + 1) * sign
    result = math.ldexp(mantissa, exponent - 127)
  end

  local rest = {}
  if count > 4 then
    for i = 5, #bytes, 1 do
      table.insert(rest, bytes[i])
    end
  end
  return result, rest
end

local function as_bytes(data)
  local bytes = {}
  for i = 1, #data, 1 do
    table.insert(bytes, string.byte(data, i))
  end

  return bytes
end

M.decode = function(data)
  local bytes = as_bytes(data)
  local address = ''
  address, bytes = read_string(bytes)
  assert(string.char(address:byte(1)) == '/', 'Invalid address')
  address = vim.split(address:sub(2), '/')

  local tags = ''
  tags, bytes = read_string(bytes)
  assert(string.char(tags:byte(1)) == ',', 'Invalid tags')
  tags = tags:sub(2)

  local entries = {}
  local entry = nil
  for i = 1, #tags, 1 do
    local tag = string.char(tags:byte(i))
    if tag == 's' then
      entry, bytes = read_string(bytes)
    elseif tag == 'i' then
      entry, bytes = read_int(bytes)
    elseif tag == 'f' then
      entry, bytes = read_float(bytes)
    else
      return nil
    end

    if entry ~= nil then
      table.insert(entries, entry)
    end
  end

  return { address = address, data = entries }
end

return M
