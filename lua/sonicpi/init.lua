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

M.setup_cmp = function()
  local has_cmp, _ = pcall(require, 'cmp')
  if not has_cmp then
    return
  end

  local keywords = require('sonicpi.opts').cmp_source.keywords
  local server_dir = require('sonicpi.opts').server_dir

  local util = require('cmp-sonicpi.util')
  local synths, sample_names = util.read_synths_and_sample_names(server_dir)
  local play_params = util.read_default_play_opts(server_dir)
  local lang = util.read_lang_from_sonic_pi(server_dir)

  keywords.synths = synths
  keywords.sample_names = sample_names
  keywords.play_params = play_params
  keywords.lang = lang
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

  require('cmp-sonicpi').setup()
end

M.setup_treesitter = function()
  local has_treesitter, ts_parsers = pcall(require, 'nvim-treesitter.parsers')
  if has_treesitter then
    ts_parsers.filetype_to_parsername.sonicpi = 'ruby'
  end
end

M.setup_mappings = function(opts)
  if not opts.mappings then
    return
  end

  local default_mapping_opts = { noremap = true, silent = true, buffer = 0 }
  local mappings = {}

  for _, mapping in ipairs(opts.mappings) do
    if type(mapping) == 'table' and (#mapping == 3 or #mapping == 4) then
      if #mapping == 3 then
        table.insert(mapping, default_mapping_opts)
      end
      table.insert(mappings, mapping)
    end
  end

  require('sonicpi.opts').mappings = mappings
end

M.setup = function(opts)
  local server_dir = opts.server_dir or find_sonic_pi_server_dir()
  if server_dir == nil or vim.trim(server_dir) == '' or vim.fn.isdirectory(server_dir) ~= 1 then
    return
  end

  vim.api.nvim_set_hl(0, 'SonicPiLogMessage', { link = 'Normal' })
  vim.api.nvim_set_hl(0, 'SonicPiLogMessageAlternate', { link = 'Debug' })
  vim.api.nvim_set_hl(0, 'SonicPiCueName', { link = 'Normal' })
  vim.api.nvim_set_hl(0, 'SonicPiCueValue', { link = 'Constant' })

  local options = require('sonicpi.opts')
  options.server_dir = vim.trim(server_dir)

  M.setup_cmp()
  M.setup_treesitter()
  M.setup_mappings(opts)
end

M.lsp_on_init = function(client, opts)
  local server_dir = (opts and opts.server_dir) or require('sonicpi.opts').server_dir
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
