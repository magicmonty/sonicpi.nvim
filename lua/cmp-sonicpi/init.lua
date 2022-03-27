local M = {}

M.setup = function()
  require('cmp').register_source('sonicpi', require('cmp-sonicpi.source').new())
end

return M
