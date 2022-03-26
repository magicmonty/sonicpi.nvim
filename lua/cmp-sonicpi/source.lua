local keywords = require('cmp-sonicpi.keywords')
local lsp = require('cmp.types').lsp
local util = require('cmp-sonicpi.util')

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
-- source.get_keyword_pattern = function(_, params)
-- return '??'
-- end

--- Return trigger characters.
--- @param params cmp.SourceBaseApiParams
--- @return string[]
source.get_trigger_characters = function(_, params)
  return { ':', ' ' }
end

local function get_simple_params(list)
  local result = {}

  for _, param in ipairs(list) do
    local text = string.format('%s:', param)

    local item = {
      label = text,
      kind = lsp.CompletionItemKind.Parameter,
      insertText = text .. ' ',
    }

    table.insert(result, item)
  end

  return result
end
local function get_synth_params(list)
  local result = {}

  for param, doc in pairs(list) do
    local text = string.format('%s:', param)

    local item = {
      label = text,
      kind = lsp.CompletionItemKind.Parameter,
      insertText = text .. ' ',
    }

    if doc ~= nil and doc ~= '' then
      item.documentation = {
        kind = lsp.MarkupKind.Markdown,
        value = doc,
      }
    end

    table.insert(result, item)
  end

  return result
end

local function get_synths(list)
  local result = {}
  for name, synth in pairs(list) do
    local item = {
      label = name,
      kind = lsp.CompletionItemKind.Enum,
      insertText = name,
    }

    if synth.doc ~= nil and synth.doc ~= '' then
      item.documentation = {
        kind = lsp.MarkupKind.Markdown,
        value = synth.doc,
      }
    end

    table.insert(result, item)
  end
  return result
end

local function get_enum(list)
  local result = {}
  for _, name in ipairs(list) do
    local item = {
      label = name,
      kind = lsp.CompletionItemKind.Enum,
      insertText = name,
    }

    table.insert(result, item)
  end
  return result
end

local function get_language_keywords(list)
  local result = {}

  for keyword, info in pairs(list) do
    local item = {
      label = keyword,
      kind = lsp.CompletionItemKind.Keyword,
      insertText = string.format('%s ', keyword),
    }

    if info.doc then
      item.documentation = {
        kind = lsp.MarkupKind.Markdown,
        value = info.doc,
      }
    end

    table.insert(result, item)
  end

  return result
end

local function get_samples(list)
  local result = {}
  for _, sample in ipairs(list) do
    local text = string.format(':%s', sample)
    local item = {
      label = text,
      kind = lsp.CompletionItemKind.Enum,
      insertText = text,
    }

    table.insert(result, item)
  end
  return result
end

---Invoke completion (required).
---  If you want to abort completion, just call the callback without arguments.
---@param params cmp.SourceCompletionApiParams
---@param callback fun(response: lsp.CompletionResponse|nil)
source.complete = function(_, params, callback)
  local result = {}
  local line = params.context.cursor_line
  local context = util.get_completion_context(line)

  if not context then
    return
  end

  local ctx = context.context_type
  P(ctx)

  if ctx == 'Synth' then
    result = get_synths(context.list)
  elseif ctx == 'SynthParam' then
    result = get_synth_params(context.list)
  elseif ctx == 'Sample' then
    result = get_samples(context.list)
  elseif ctx == 'FXParam' then
    result = get_simple_params(context.list)
  elseif
    ctx == 'Chord'
    or ctx == 'Scale'
    or ctx == 'FX'
    or ctx == 'RandomSource'
    or ctx == 'Examples'
    or ctx == 'Tuning'
  then
    result = get_enum(context.list)
  elseif ctx == 'Keyword' then
    result = get_language_keywords(context.list)
  elseif
    ctx == 'LangParam'
    or ctx == 'PlayParam'
    or ctx == 'SampleParam'
  then
    result = get_synth_params(context.list)
  end

  if #result > 0 then
    callback({ items = result, isIncomplete = false })
  end
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
