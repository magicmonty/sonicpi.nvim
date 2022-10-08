local lsp = require('cmp.types').lsp
local lexer = require('cmp-sonicpi.lexer')

local source = {}

source.new = function()
  local self = setmetatable({}, { __index = source })
  return self
end

--- Return the source is available or not.
--- @return boolean
source.is_available = function(_)
  return vim.bo.filetype == 'sonicpi'
end

--- Return the source name for some information.
source.get_debug_name = function(_)
  return 'Sonic Pi'
end

--- Return trigger characters.
--- @param params cmp.SourceBaseApiParams
--- @return string[]
source.get_trigger_characters = function(_, params)
  return { ':', ' ', ',' }
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
    local text = string.format('%s:', param:match('[^:]+'))

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
    local text = string.format('%s', sample)
    local item = {
      label = text,
      kind = lsp.CompletionItemKind.Enum,
      insertText = text,
    }

    table.insert(result, item)
  end

  table.sort(result, function(a, b)
    return a.label < b.label
  end)
  return result
end

local function is_sample_keyword(keyword)
  return keyword == 'sample'
      or keyword == 'sample_info'
      or keyword == 'sample_duration'
      or keyword == 'use_sample_bpm'
      or keyword == 'sample_buffer'
      or keyword == 'sample_loaded?'
      or keyword == 'load_sample'
      or keyword == 'load_samples'
end

local function is_cue_keyword(keyword)
  return keyword == 'sync'
      or keyword == 'sync:'
      or keyword == 'cue'
      or keyword == 'get'
      or keyword == 'get['
      or keyword == 'set'
end

local function is_synth_keyword(keyword)
  return keyword == 'with_synth'
      or keyword == 'use_synth'
      or keyword == 'synth'
end

local function get_completion_context(line)
  local keywords = require('sonicpi.opts').cmp_source.keywords
  local words = lexer.get_words(line)
  local context = lexer.get_context(words)
  local last = context.last_word
  local first = context.first_word
  if is_sample_keyword(last)
  then
    return { context_type = 'Sample', list = keywords.sample_names }
  elseif is_sample_keyword(first) and #words == 2 and not line:match(':[^,]*,.*$') then
    return { context_type = 'Sample', list = keywords.sample_names }
  elseif is_cue_keyword(last) then
    return { context_type = 'CuePath' }
  elseif last == 'with_fx' then
    return { context_type = 'FX', list = keywords.fx }
  elseif is_synth_keyword(last) then
    return { context_type = 'Synth', list = keywords.synths }
  elseif last == 'load_example' then
    return { context_type = 'Examples', list = keywords.example_names }
  elseif last == 'use_random_source' or last == 'with_random_source' then
    return { context_type = 'RandomSource', list = keywords.random_sources }
  elseif context.second_to_last_word == 'scale' then
    return { context_type = 'Scale', list = keywords.scales }
  elseif first == 'chord' and last ~= 'chord' and context.second_to_last_word ~= 'chord' then
    return { context_type = 'Chord', list = keywords.chords }
  elseif last == 'use_tuning' or last == 'with_tuning' then
    return { context_type = 'Tuning', list = keywords.tunings }
  elseif #words >= 2 and first == 'with_fx' then
    if last and not last:match('.*:$') then
      if keywords.fx_params[context.second_word] then
        return { context_type = 'FXParam', list = keywords.fx_params[context.second_word] }
      end
    end
  elseif #words >= 2 and first == 'synth' then
    if last and not last:match('.*:$') then
      if keywords.synths[context.second_word] then
        return { context_type = 'SynthParam', list = keywords.synths[context.second_word].args }
      end
    end
  elseif first == 'use_synth_defaults' or first == 'with_synth_defaults' then
    if last and not last:match('.*:$') then
      return { context_type = 'SynthParam', list = keywords.synths['common_parameters'] }
    end
  elseif #words >= 2 and first == 'play' then
    if last and not last:match('.*:$') then
      return { context_type = 'PlayParam', list = keywords.play_params }
    end
  elseif #words >= 2 and first == 'sample' then
    if last and not last:match('.*:$') then
      return { context_type = 'SampleParam', list = keywords.sample_params.sample }
    end
  elseif first == 'use_sample_defaults' or first == 'with_sample_defaults' then
    if last and not last:match('.*:$') then
      return { context_type = 'SampleParam', list = keywords.sample_params[context.first_word] }
    end
  elseif first
      and (first == 'midi' or first:match('^midi_') or first == 'use_midi_defaults' or first == 'with_midi_defaults')
      and last == 'port:'
  then
    return {
      context_type = 'MidiOuts',
      list = { --[[ TODO: Get Midi out ports per OSC ]]
      },
    }
  elseif #words >= 2 and first == 'midi' then
    if last and not last:match('.*:$') then
      return { context_type = 'MidiParam', list = keywords.midi_params }
    end
  elseif keywords.lang[first]
      and keywords.lang[first].opts
      and (keywords.lang[first].args == nil or #words >= require('cmp-sonicpi.util').length(keywords.lang[first].args))
  then
    return { context_type = 'LangParam', list = keywords.lang[first].opts }
  elseif #words <= 1 or last == '=' then
    return { context_type = 'Keyword', list = keywords.lang }
  end

  return nil
end

---Invoke completion (required).
---  If you want to abort completion, just call the callback without arguments.
---@param params cmp.SourceCompletionApiParams
---@param callback fun(response: lsp.CompletionResponse|nil)
source.complete = function(_, params, callback)
  local result = {}
  local line = params.context.cursor_before_line
  local context = get_completion_context(line)

  if not context then
    return
  end

  local ctx = context.context_type

  if ctx == 'Synth' then
    result = get_synths(context.list)
  elseif ctx == 'SynthParam' then
    result = get_synth_params(context.list)
  elseif ctx == 'Sample' then
    result = get_samples(context.list)
  elseif ctx == 'FXParam' then
    result = get_simple_params(context.list)
  elseif ctx == 'Chord'
      or ctx == 'Scale'
      or ctx == 'FX'
      or ctx == 'RandomSource'
      or ctx == 'Examples'
      or ctx == 'Tuning'
  then
    result = get_enum(context.list)
  elseif ctx == 'Keyword' then
    result = get_language_keywords(context.list)
  elseif ctx == 'LangParam' or ctx == 'PlayParam' or ctx == 'SampleParam' then
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
