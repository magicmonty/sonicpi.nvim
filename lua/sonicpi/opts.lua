local fixed_keywords = require('cmp-sonicpi.keywords')
local default_mapping_opts = { noremap = true, silent = true, buffer = 0 }

return {
  server_dir = '',
  cmp_source = {
    keywords = {
      synths = {},
      sample_names = nil,
      play_params = {},
      sample_params = {},
      lang = {},
      scales = fixed_keywords.scales,
      chords = fixed_keywords.chords,
      tunings = fixed_keywords.tunings,
      midi_params = fixed_keywords.midi_params,
      example_names = fixed_keywords.example_names,
      random_sources = fixed_keywords.random_sources,
      fx = fixed_keywords.fx,
      fx_params = fixed_keywords.fx_params,
    },
  },
  remote = {
    ports = {
      daemon = nil,
      gui = nil,
      osc_cues = nil,
      phx = nil,
      sc_synth = nil,
      spider = nil,
      token = nil,
    },
    lifecycle = {
      stop_daemon = 0,
      daemon_started = 0,
    },
  },
  mappings = {
    { 'n', '<leader>s', require('sonicpi.remote').stop, default_mapping_opts },
    { 'i', '<M-s>', require('sonicpi.remote').stop, default_mapping_opts },
    { 'n', '<leader>r', require('sonicpi.remote').run_current_buffer, default_mapping_opts },
    { 'i', '<M-r>', require('sonicpi.remote').run_current_buffer, default_mapping_opts },
  },
}
