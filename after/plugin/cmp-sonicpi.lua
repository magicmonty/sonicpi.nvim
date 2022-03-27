require('cmp-sonicpi').setup()

local ok, icons = pcall(require, 'nvim-web-devicons')
if ok then
  icons.set_icon({
    ['.sonicpi'] = { icon = '', color = '#FF1493', name = 'SonicPi' },
  })
  icons.set_icon({
    sonicpi = { icon = '', color = '#FF1493', name = 'SonicPi' },
  })
end
