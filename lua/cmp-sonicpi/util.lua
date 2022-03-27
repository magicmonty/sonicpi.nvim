local M = {}

M.length = function(tab)
  local count = 0
  for _ in pairs(tab) do
    count = count + 1
  end
  return count
end

M.has_value = function(tab, val)
  for _, v in ipairs(tab) do
    if v == val then
      return true
    end
  end
  return false
end

local function parse_arg_info(member)
  local result = {}

  local value = vim.trim(table.concat(member, '\n')):match('{(.*)}')

  for key, doc in value:gmatch(':([^%s]+)%s*=>%s*{[^{}]*:doc%s*=>%s*"([^"]*)"[^{}]*}') do
    result[key] = doc
  end

  return result
end

local function find_base_classes(class, classes)
  if class == nil then
    return {}
  end

  if class.base_class == nil then
    return {}
  end

  local result = {}

  local base_class = classes[class.base_class]
  if base_class ~= nil then
    table.insert(result, class.base_class)

    for _, class_name in ipairs(find_base_classes(base_class, classes)) do
      if result[class_name] == nil then
        table.insert(result, class_name)
      end
    end
  end

  return result
end

local function decorate_base_classes(classes)
  for _, class in pairs(classes) do
    class.base_classes = find_base_classes(class, classes)
  end
  return classes
end

local function get_specific_arg_info(class, classes)
  if class == nil then
    return {}
  end

  local result = class.members.specific_arg_info or {}

  if class.direct_base_class == nil then
    return result
  end

  local base_class = classes[class.direct_base_class]
  if base_class ~= nil then
    for name, doc in pairs(get_specific_arg_info(base_class, classes)) do
      if result[name] == nil then
        result[name] = doc
      end
    end
  end

  return result
end

local function get_default_arg_info(class, classes)
  if class == nil then
    return {}
  end

  local result = class.members.default_arg_info or {}

  if class.direct_base_class == nil then
    return result
  end

  local base_class = classes[class.direct_base_class]
  if base_class ~= nil then
    for name, doc in pairs(get_default_arg_info(base_class, classes)) do
      if result[name] == nil then
        result[name] = doc
      end
    end
  end

  return result
end

local function get_arg_info(class, classes)
  if class == nil then
    return {}
  end

  local result = get_default_arg_info(class, classes)

  for name, doc in pairs(get_specific_arg_info(class, classes)) do
    result[name] = doc
  end

  return result
end

local function get_args_from_base_classes(class, classes)
  if class == nil then
    return {}
  end

  local result = class.members.args or {}

  if class.direct_base_class == nil then
    return result
  end

  local base_class = classes[class.direct_base_class]
  if base_class ~= nil then
    for _, arg in ipairs(get_args_from_base_classes(base_class, classes)) do
      if result[arg] == nil then
        table.insert(result, arg)
      end
    end
  end

  return result
end

local function clean_classes(classes)
  local results = {}
  for class_name, class in pairs(classes) do
    local cleaned_members = {}
    for member_name, member in pairs(class.members) do
      if member_name == 'doc' then
        local value = vim.trim(table.concat(member, '\n')):match('"(.*)"')
        cleaned_members.doc = value
      end
      if member_name == 'synth_name' then
        cleaned_members.synth_name = vim.trim(table.concat(member, '\n')):match('"(.*)"')
      end
      if member_name == 'name' then
        cleaned_members.name = vim.trim(table.concat(member, '\n')):match('"(.*)"')
      end
      if member_name == 'arg_defaults' then
        local value = vim.trim(table.concat(member, '\n')):match('{(.*)}')
        value = value:gsub('%s', '')
        cleaned_members.args = {}
        for _, v in ipairs(vim.split(value, ',', true)) do
          table.insert(cleaned_members.args, v:match(':([^:=>]+)=>'))
        end
      end
      if member_name == 'specific_arg_info' then
        cleaned_members.specific_arg_info = parse_arg_info(member)
      end
      if member_name == 'default_arg_info' then
        cleaned_members.default_arg_info = parse_arg_info(member)
      end
    end

    class.members = cleaned_members
    results[class_name] = {
      direct_base_class = class.base_class,
      base_classes = class.base_classes,
      members = class.members,
    }
  end

  local cleaned_results = {}
  for _, class in pairs(results) do
    local args = get_args_from_base_classes(class, results)
    local arg_infos = get_arg_info(class, results)
    local new_args = {}

    for _, arg in ipairs(args) do
      local arg_info = arg_infos[arg]
      if arg_info ~= nil then
        new_args[arg] = arg_info
      else
        new_args[arg] = ''
      end
    end

    if class.members.synth_name ~= nil and class.members.synth_name:match('%s') == nil then
      local doc = class.members.doc or ''
      if (class.members.name or '') ~= '' then
        doc = '# ' .. class.members.name .. '\n\n' .. doc
      end

      if M.has_value(class.base_classes, 'SonicPiSynth') and not M.has_value(class.base_classes, 'StudioInfo') then
        cleaned_results[':' .. class.members.synth_name] = {
          args = new_args,
          doc = vim.trim(doc),
        }
      end
    end
  end

  return cleaned_results
end

local function parse_classes(lines)
  local classes = {}
  local level = 0
  local current_class = nil
  local current_member = nil

  for _, line in ipairs(lines) do
    if line:match('class (%w+)') ~= nil then
      current_class = line:match('class (%w+)')
      if classes[current_class] == nil then
        classes[current_class] = {
          members = {},
        }
      end

      if line:match('class %w+ < (%w+)') ~= nil then
        classes[current_class].base_class = line:match('class %w+ < (%w+)')
      end

      level = 1
      current_member = nil
    elseif line:match('^%s*#') ~= nil then
      if current_member ~= nil and current_class ~= nil then
        table.insert(classes[current_class].members[current_member], line)
      end
    elseif line:match('^%s*def%s+([^%s]+)') ~= nil then
      current_member = line:match('^%s*def%s+([^%s]+)')
      level = level + 1
      classes[current_class].members[current_member] = {}
    elseif line:match('^%s*end%s*$') ~= nil then
      level = level - 1
      if level == 0 then
        current_class = nil
      elseif level == 1 then
        current_member = nil
      end
    else
      if current_member ~= nil then
        table.insert(classes[current_class].members[current_member], line)
      end
      if line:match('%sdo%s') ~= nil or line:match(' do$') ~= nil or line:match('^%s*if ') ~= nil then
        level = level + 1
      end
    end
  end

  return clean_classes(decorate_base_classes(classes))
end

local function read_samples(lines)
  local samples = {}
  local sample_section_found = false
  local sample_section = ''

  for _, line in ipairs(lines) do
    if line:match('@@grouped_samples') ~= nil then
      sample_section_found = true
    elseif line:match('@@all_samples') then
      break
    elseif sample_section_found then
      sample_section = sample_section .. line
    end
  end

  for s in sample_section:gsub('%s', ''):gmatch(':samples=>%[([^%[%]]+)%]') do
    if s ~= nil then
      for _, sa in ipairs(vim.split(s, ',', true)) do
        if sa ~= nil then
          table.insert(samples, sa)
        end
      end
    end
  end

  return samples
end

M.read_synths_and_sample_names = function(server_dir)
  if not server_dir then
    vim.notify('No server directory specified', 'error')
    return {}
  end
  if vim.fn.isdirectory(server_dir) == 0 then
    vim.notify('Server directory "' .. server_dir .. '" does not exist', 'error')
    return {}
  end

  local lines = {}
  for line in io.lines(server_dir .. '/ruby/lib/sonicpi/synths/synthinfo.rb') do
    table.insert(lines, line)
  end

  local synths = parse_classes(lines)
  local sample_names = read_samples(lines)

  return synths, sample_names
end

local known_keywords = {
  'all_sample_names',
  'assert',
  'assert_equal',
  'assert_error',
  'assert_not',
  'assert_not_equal',
  'assert_similar',
  'at',
  'beat',
  'block_duration',
  'block_slept?',
  'bools',
  'bt',
  'buffer',
  'choose',
  'chord',
  'chord_degree',
  'chord_invert',
  'chord_names',
  'clear',
  'comment',
  'control',
  'cue',
  'current_arg_checks',
  'current_beat_duration',
  'current_bpm',
  'current_bpm_mode',
  'current_cent_tuning',
  'current_debug',
  'current_midi_defaults',
  'current_octave',
  'current_random_seed',
  'current_random_source',
  'current_sample_defaults',
  'current_sched_ahead_time',
  'current_synth',
  'current_synth_defaults',
  'current_time',
  'current_transpose',
  'current_volume',
  'dec',
  'define',
  'defonce',
  'degree',
  'density',
  'dice',
  'doubles',
  'eval_file',
  'factor?',
  'fx_names',
  'get',
  'halves',
  'hz_to_midi',
  'in_thread',
  'inc',
  'kill',
  'knit',
  'line',
  'live_audio',
  'live_loop',
  'load_buffer',
  'load_example',
  'load_sample',
  'load_samples',
  'load_synthdefs',
  'look',
  'loop',
  'map',
  'midi',
  'midi_all_notes_off',
  'midi_cc',
  'midi_channel_pressure',
  'midi_clock_beat',
  'midi_clock_tick',
  'midi_continue',
  'midi_local_control_off',
  'midi_local_control_on',
  'midi_mode',
  'midi_note_off',
  'midi_note_on',
  'midi_notes',
  'midi_pc',
  'midi_pitch_bend',
  'midi_poly_pressure',
  'midi_raw',
  'midi_reset',
  'midi_sound_off',
  'midi_start',
  'midi_stop',
  'midi_sysex',
  'midi_to_hz',
  'ndefine',
  'note',
  'note_info',
  'note_range',
  'octs',
  'on',
  'one_in',
  'osc',
  'osc_send',
  'pick',
  'pitch_to_ratio',
  'play',
  'play_chord',
  'play_pattern',
  'play_pattern_timed',
  'print',
  'puts',
  'quantise',
  'ramp',
  'rand',
  'rand_back',
  'rand_i',
  'rand_i_look',
  'rand_look',
  'rand_reset',
  'rand_skip',
  'range',
  'ratio_to_pitch',
  'rdist',
  'reset',
  'reset_mixer!',
  'rest?',
  'ring',
  'rrand',
  'rrand_i',
  'rt',
  'run_code',
  'run_file',
  'sample',
  'sample_buffer',
  'sample_duration',
  'sample_free',
  'sample_free_all',
  'sample_groups',
  'sample_info',
  'sample_loaded?',
  'sample_names',
  'sample_paths',
  'scale',
  'scale_names',
  'scsynth_info',
  'set',
  'set_audio_latency!',
  'set_cent_tuning!',
  'set_control_delta!',
  'set_link_bpm!',
  'set_mixer_control!',
  'set_recording_bit_depth!',
  'set_sched_ahead_time!',
  'set_volume!',
  'shuffle',
  'sleep',
  'spark',
  'spark_graph',
  'spread',
  'status',
  'stop',
  'stretch',
  'sync',
  'sync_bpm',
  'synth',
  'synth_names',
  'tick',
  'tick_reset',
  'tick_reset_all',
  'tick_set',
  'time_warp',
  'uncomment',
  'use_arg_bpm_scaling',
  'use_arg_checks',
  'use_bpm',
  'use_bpm_mul',
  'use_cent_tuning',
  'use_cue_logging',
  'use_debug',
  'use_merged_midi_defaults',
  'use_merged_sample_defaults',
  'use_merged_synth_defaults',
  'use_midi_defaults',
  'use_midi_logging',
  'use_octave',
  'use_osc',
  'use_osc_logging',
  'use_random_seed',
  'use_random_source',
  'use_real_time',
  'use_sample_bpm',
  'use_sample_defaults',
  'use_sched_ahead_time',
  'use_synth',
  'use_synth_defaults',
  'use_timing_guarantees',
  'use_transpose',
  'use_tuning',
  'vector',
  'version',
  'vt',
  'wait',
  'with_arg_bpm_scaling',
  'with_sample_pack',
  'with_arg_checks',
  'with_bpm',
  'with_bpm_mul',
  'with_cent_tuning',
  'with_cue_logging',
  'with_debug',
  'with_fx',
  'with_merged_midi_defaults',
  'with_merged_sample_defaults',
  'with_merged_synth_defaults',
  'with_midi_defaults',
  'with_midi_logging',
  'with_octave',
  'with_osc',
  'with_osc_logging',
  'with_random_seed',
  'with_random_source',
  'with_real_time',
  'with_sample_bpm',
  'with_sample_defaults',
  'with_sched_ahead_time',
  'with_swing',
  'with_synth',
  'with_synth_defaults',
  'with_timing_guarantees',
  'with_transpose',
  'with_tuning',
}

local function read_lang_from_file(file_path)
  local lines = {}
  for line in io.lines(file_path) do
    table.insert(lines, line)
  end

  local doc_found = false
  local last_keyword = nil
  local doc = {}

  for _, line in ipairs(lines) do
    local match = line:match('^%s*def%s+([^%s(%[]+)')
    if match then
      if M.has_value(known_keywords, match) then
        last_keyword = match
        doc[last_keyword] = { vim.trim(line) }
      else
        last_keyword = nil
      end
      doc_found = false
    elseif last_keyword and line:match('^%s*doc%s+') then
      doc_found = true
      table.insert(doc[last_keyword], vim.trim(line:match('^%s*doc%s+(.*)')))
    elseif last_keyword and doc_found and line:match('^*s* def%s') then
      doc_found = false
      last_keyword = nil
    elseif last_keyword and doc_found then
      local l = vim.trim(line)
      if l ~= '' then
        table.insert(doc[last_keyword], l)
      end
    end
  end

  return doc
end

local function parse_args(args)
  if not args or vim.trim(args) == '' then
    return nil
  end

  local opts = {}
  local found_arg = false

  for arg_name, arg_type in vim.trim(args):gmatch('%[:([^:]+),%s*:([^%]]+)%]') do
    opts[arg_name] = ':' .. arg_type
    found_arg = true
  end

  if found_arg then
    return opts
  end

  return nil
end

local function parse_opts(line, default_play_opts)
  if line and line:match('DEFAULT_PLAY_OPTS') then
    return default_play_opts
  end

  line = (line or ''):match('{(.*)}?')
  if not line or vim.trim(line) == '' then
    return nil
  end
  line = vim.trim(line)
  local arg = line:match('^([^:]+):') or line:match('^(:[^%s=>]+)')
  if not arg then
    return nil
  end

  local opts = {}
  local found_opt = false

  for opt_name, doc in line:gmatch('(:?[^%s=>:,]+):?[%s=>{]*"([^"]+)"') do
    doc = vim.trim(doc)
    if doc ~= '' and doc ~= 'nil' then
      opts[opt_name] = doc
      found_opt = true
    end
  end

  if found_opt then
    return opts
  end

  return nil
end

local function parse_doc(doc, default_play_opts)
  if not doc then
    return {}
  end

  local item = {}

  local current_section = nil
  local is_example_section = false
  local opts_started = false
  for _, line in ipairs(doc) do
    local match = line:match('^(%w[^:]+):')
    if match and not is_example_section and not opts_started then
      current_section = match
      if current_section == 'examples' then
        is_example_section = true
      end
      line = vim.trim(line):match('^[^:]+:%s*"(.*)",?$') or vim.trim(line):match('^[^:]+:%s*(.*),?$')
      item[current_section] = vim.trim(line)
      if current_section == 'opts' then
        if vim.trim(line):match('{') and not vim.trim(line):match('},?$') then
          opts_started = true
        else
          opts_started = false
        end
      end
    elseif current_section then
      line = vim.trim(line):match('^"(.*)",?$') or vim.trim(line)
      if current_section == 'doc' or is_example_section then
        item[current_section] = vim.trim(item[current_section] .. '\n' .. line)
      elseif current_section == 'opts' then
        if line ~= 'nil,' and line ~= '{}' then
          item[current_section] = vim.trim(item[current_section] .. line)
        else
          opts_started = false
        end
      else
        item[current_section] = vim.trim(item[current_section] .. line)
      end
      if opts_started and vim.trim(line):match('},?$') then
        opts_started = false
      end
    end
  end

  local parsed = {}

  local documentation = ''
  if item.summary then
    documentation = documentation .. item.summary
  end

  local args = parse_args(item.args)

  if args then
    parsed.args = args
    documentation = documentation .. '\n\n## Arguments\n\n'
    for k, v in pairs(args) do
      documentation = documentation .. '* `' .. vim.trim(k) .. '` => `' .. vim.trim(v) .. '`\n'
    end
    documentation = vim.trim(documentation)
  end

  local opts = parse_opts(item.opts, default_play_opts)
  if opts then
    parsed.opts = opts
    documentation = documentation .. '\n\n## Optional Arguments\n\n'
    for k, v in pairs(opts) do
      documentation = documentation .. '* `' .. vim.trim(k) .. '` => `' .. vim.trim(v) .. '`\n'
    end
    documentation = vim.trim(documentation)
  elseif item.opts ~= 'nil,' then
  end

  if documentation ~= '' then
    documentation = documentation .. '\n\n'

    if item.doc then
      documentation = documentation .. '## Description\n\n' .. item.doc .. '\n\n'
    end
  end

  if documentation ~= '' then
    parsed.doc = documentation
  end

  return parsed
end

M.read_default_play_opts = function(server_dir)
  if not server_dir then
    vim.notify('No server directory specified', 'error')
    return {}
  end
  if vim.fn.isdirectory(server_dir) == 0 then
    vim.notify('Server directory "' .. server_dir .. '" does not exist', 'error')
    return {}
  end

  local result = {}

  local start_found = false
  local opts = {}
  for line in io.lines(server_dir .. '/ruby/lib/sonicpi/lang/sound.rb') do
    if line:match('DEFAULT_PLAY_OPTS') then
      start_found = true
    elseif start_found then
      if vim.trim(line):match('}$') then
        table.insert(opts, vim.trim(line):match('^(.*)}$'))
        break
      else
        table.insert(opts, vim.trim(line))
      end
    end
  end

  for _, opt in ipairs(opts) do
    local name, value = opt:match('^([^:]+):%s*"(.*)",?$')
    if name and value then
      result[name] = value
    end
  end

  return result
end

M.read_lang_from_sonic_pi = function(server_dir)
  if not server_dir then
    vim.notify('No server directory specified', 'error')
    return {}
  end
  if vim.fn.isdirectory(server_dir) == 0 then
    vim.notify('Server directory "' .. server_dir .. '" does not exist', 'error')
    return {}
  end

  local lang_dir = server_dir .. '/ruby/lib/sonicpi/lang'
  local default_play_opts = M.read_default_play_opts(server_dir)
  local core = read_lang_from_file(lang_dir .. '/core.rb')
  local sound = read_lang_from_file(lang_dir .. '/sound.rb')
  local wt = read_lang_from_file(lang_dir .. '/western_theory.rb')
  local midi = read_lang_from_file(lang_dir .. '/midi.rb')

  local doc = {}
  for k, v in pairs(core) do
    doc[k] = v
  end

  for k, v in pairs(sound) do
    doc[k] = v
  end

  for k, v in pairs(wt) do
    doc[k] = v
  end

  for k, v in pairs(midi) do
    doc[k] = v
  end

  local lang = {}
  for _, k in ipairs(known_keywords) do
    lang[k] = parse_doc(doc[k], default_play_opts)
  end

  return lang
end

return M
