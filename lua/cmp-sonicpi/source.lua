local keywords = require('cmp-sonicpi.keywords')
local lsp = require('cmp.types').lsp

local function has_value(tab, val)
  for _, value in ipairs(tab) do
    if value == val then
      return true
    end
  end

  return false
end

local function get_first_word(val)
  local first_space = string.find(val, ' ')
  if first_space then
    return string.sub(val, 1, first_space - 1)
  else
    return val
  end
end

local source = {}

source.new = function()
  local self = setmetatable({}, { __index = source })
  return self
end

--- Return the source is available or not.
--- @return boolean
source.is_available = function(_)
  return vim.bo.filetype == 'ruby'
end

--- Return the source name for some information.
source.get_debug_name = function(_)
  return 'sonicpi'
end

--- Return keyword pattern which will be used...
---   1. Trigger keyword completion
---   2. Detect menu start offset
---   3. Reset completion state
--- @param params cmp.SourceBaseApiParams
--- @return string
source.get_keyword_pattern = function(_, params)
  return '.'
end

--- Return trigger characters.
--- @param params cmp.SourceBaseApiParams
--- @return string[]
-- source.get_trigger_characters = function(_, params)
-- return { ':' }
-- end

---Invoke completion (required).
---  If you want to abort completion, just call the callback without arguments.
---@param params cmp.SourceCompletionApiParams
---@param callback fun(response: lsp.CompletionResponse|nil)
source.complete = function(_, params, callback)
  local items = keywords.lang
  local itemKind = lsp.CompletionItemKind.Keyword

  local result = {}
  for _, item in ipairs(items) do
    table.insert(result, { label = item, kind = itemKind, insertText = string.format('%s ', item) })
  end

  callback({ items = result, isIncomplete = false })
end

---Resolve completion item that will be called when the item selected or before the item confirmation.
---@param completion_item lsp.CompletionItem
---@param callback fun(completion_item: lsp.CompletionItem|nil)
-- function source:resolve(completion_item, callback)
-- DN(completion_item)
-- callback(completion_item)
-- end

---Execute command that will be called when after the item confirmation.
---@param completion_item lsp.CompletionItem
---@param callback fun(completion_item: lsp.CompletionItem|nil)
-- function source:execute(completion_item, callback)
-- callback(completion_item)
-- end

-- cmp.register_source('sonicpi', source.new())
return source
-- vim: foldlevel=99
