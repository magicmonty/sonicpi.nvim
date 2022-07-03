local ok, icons = pcall(require, 'nvim-web-devicons')
if ok then
  icons.set_icon({
    ['.sonicpi'] = { icon = '', color = '#FF1493', name = 'SonicPi' },
  })
  icons.set_icon({
    sonicpi = { icon = '', color = '#FF1493', name = 'SonicPi' },
  })
end

local has_luasnip, luasnip = pcall(require, 'luasnip')
if has_luasnip then
  luasnip.add_snippets('sonicpi', require('sonicpi.snippets'))
end
