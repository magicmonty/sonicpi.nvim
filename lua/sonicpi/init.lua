local M = {}

local function find_sonic_pi_server_dir()
  local known_paths = {
    '/opt/sonic-pi/app/server',
    '/usr/lib/sonic-pi/app/server',
    '/usr/lib/sonicpi/app/server',
    '/usr/share/sonic-pi/app/server',
    '/usr/share/sonicpi/app/server',
  }

  for _, path in ipairs(known_paths) do
    if vim.fn.isdirectory(path) == 1 then
      return path
    end
  end

  return nil
end

M.setup = function(opts)
  local server_dir = opts.server_dir or find_sonic_pi_server_dir()
  local options = {}

  vim.highlight.link('SonicPiLogMessage', 'Normal')
  vim.highlight.link('SonicPiLogMessageAlternate', 'Debug')
  vim.highlight.link('SonicPiCueName', 'Normal')
  vim.highlight.link('SonicPiCueValue', 'Constant')

  if server_dir ~= nil and vim.trim(server_dir) ~= '' then
    options.server_dir = vim.trim(server_dir)

    if vim.fn.isdirectory(options.server_dir) == 1 then
      local util = require('cmp-sonicpi.util')
      local fixed_keywords = require('cmp-sonicpi.keywords')
      local synths, sample_names = util.read_synths_and_sample_names(options.server_dir)
      local play_params = util.read_default_play_opts(options.server_dir)
      local lang = util.read_lang_from_sonic_pi(options.server_dir)

      local keywords = {
        synths = synths,
        sample_names = sample_names,
        play_params = play_params,
        lang = lang,
        scales = fixed_keywords.scales,
        chords = fixed_keywords.chords,
        tunings = fixed_keywords.tunings,
        midi_params = fixed_keywords.midi_params,
        example_names = fixed_keywords.example_names,
        random_sources = fixed_keywords.random_sources,
        fx = fixed_keywords.fx,
        fx_params = fixed_keywords.fx_params,
      }

      keywords.sample_params = {
        sample = {},
        sample_duration = lang['sample_duration'].opts,
        use_sample_bpm = lang['use_sample_bpm'].opts,
      }

      for name, doc in pairs(lang['sample'].opts) do
        name = name:match('[^:]+')
        if name and not name:match('\\') then
          keywords.sample_params.sample[name] = doc
        end
      end

      keywords.sample_params.use_sample_defaults = keywords.sample_params.sample
      keywords.sample_params.with_sample_defaults = keywords.sample_params.sample
      keywords.sample_params.with_sample_bpm = keywords.sample_params.use_sample_bpm

      options.keywords = keywords

      require('cmp-sonicpi').setup()
    end
  end

  M.opts = options
  vim.schedule(function()
    vim.g.sonic_pi_opts = M.opts
  end)
end

M.lsp_on_init = function(client, opts)
  local server_dir = opts and opts.server_dir or M.opts.server_dir
  if not server_dir then
    return
  end

  if client.name == 'solargraph' and vim.api.nvim_buf_get_option(0, 'filetype') == 'sonicpi' then
    local cfg = client.config.settings.solargraph
    client.config.settings.single_file_support = true
    cfg.diagnostics = false
    cfg.reporters = { 'typecheck', 'update_errors' }

    cfg.include = cfg.include or {}
    table.insert(cfg.include, server_dir .. '/ruby/lib/sonicpi/**/*.rb')

    cfg.require = cfg.require or {}
    table.insert(cfg.require, server_dir .. '/core')
    table.insert(cfg.require, server_dir .. '/ruby/lib/sonicpi/lang/core')
  end
end

return M
