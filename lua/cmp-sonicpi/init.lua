local source = require('cmp-sonicpi.source')

local M = {}

M.setup = function()
  require('cmp').register_source('sonicpi', source.new())
end

return M
