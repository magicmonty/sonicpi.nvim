local M = {}

M.scales = {
  ':acem_asiran',
  ':acem_kurdi',
  ':acemli_rast',
  ':aeolian',
  ':ahirbhairav',
  ':augmented',
  ':augmented2',
  ':bartok',
  ':bayati',
  ':bayati_2',
  ':bayati_araban',
  ':bestenigar',
  ':bhairav',
  ':blues_major',
  ':blues_minor',
  ':buselik',
  ':buselik_2',
  ':cargah',
  ':chinese',
  ':chromatic',
  ':diatonic',
  ':diminished',
  ':diminished2',
  ':dorian',
  ':dugah',
  ':dugah_2',
  ':egyptian',
  ':enigmatic',
  ':evcara',
  ':evcara_2',
  ':evcara_3',
  ':evcara_4',
  ':evic',
  ':evic_2',
  ':ferahfeza',
  ':ferahfeza_2',
  ':ferahnak',
  ':gong',
  ':gulizar',
  ':harmonic_major',
  ':harmonic_minor',
  ':hex_aeolian',
  ':hex_dorian',
  ':hex_major6',
  ':hex_major7',
  ':hex_phrygian',
  ':hex_sus',
  ':hicaz',
  ':hicaz_2',
  ':hicaz_humayun',
  ':hicaz_humayun_2',
  ':hicazkar',
  ':hicazkar_2',
  ':hindu',
  ':hirajoshi',
  ':hungarian_minor',
  ':huseyni',
  ':huseyni_2',
  ':huzzam',
  ':huzzam_2',
  ':indian',
  ':ionian',
  ':isfahan',
  ':isfahan_2',
  ':iwato',
  ':jiao',
  ':karcigar',
  ':kumoi',
  ':kurdi',
  ':kurdili_hicazkar',
  ':kurdili_hicazkar_2',
  ':kurdili_hicazkar_3',
  ':kurdili_hicazkar_4',
  ':kurdili_hicazkar_5',
  ':leading_whole',
  ':locrian',
  ':locrian_major',
  ':lydian',
  ':lydian_minor',
  ':mahur',
  ':major',
  ':major_pentatonic',
  ':marva',
  ':melodic_major',
  ':melodic_minor',
  ':melodic_minor_asc',
  ':melodic_minor_desc',
  ':messiaen1',
  ':messiaen2',
  ':messiaen3',
  ':messiaen4',
  ':messiaen5',
  ':messiaen6',
  ':messiaen7',
  ':minor',
  ':minor_pentatonic',
  ':mixolydian',
  ':muhayyer',
  ':neapolitan_major',
  ':neapolitan_minor',
  ':neva',
  ':neva_2',
  ':nihavend',
  ':nihavend_2',
  ':octatonic',
  ':pelog',
  ':phrygian',
  ':prometheus',
  ':purvi',
  ':rast',
  ':ritusen',
  ':romanian_minor',
  ':saba',
  ':scriabin',
  ':sedaraban',
  ':sedaraban_2',
  ':segah',
  ':segah_2',
  ':sehnaz',
  ':sehnaz_2',
  ':sehnaz_3',
  ':sehnaz_4',
  ':sevkefza',
  ':sevkefza_2',
  ':sevkefza_3',
  ':shang',
  ':spanish',
  ':sultani_yegah',
  ':sultani_yegah_2',
  ':super_locrian',
  ':suzidil',
  ':suzidil_2',
  ':suznak',
  ':suznak_2',
  ':tahir',
  ':tahir_2',
  ':todi',
  ':ussak',
  ':uzzal',
  ':uzzal_2',
  ':whole',
  ':whole_tone',
  ':yegah',
  ':yegah_2',
  ':yu',
  ':zhi',
  ':zirguleli_hicaz',
  ':zirguleli_hicaz_2',
  ':zirguleli_suznak',
  ':zirguleli_suznak_2',
  ':zirguleli_suznak_3',
}

M.chords = {
  "'1'",
  "'5'",
  "'+5'",
  "'m+5'",
  ':sus2',
  ':sus4',
  "'6'",
  ':m6',
  "'7sus2'",
  "'7sus4'",
  "'7-5'",
  ':halfdiminished',
  "'7+5'",
  "'m7+5'",
  "'9'",
  ':m9',
  "'m7+9'",
  ':maj9',
  "'9sus4'",
  "'6*9'",
  "'m6*9'",
  "'7-9'",
  "'m7-9'",
  "'7-10'",
  "'7-11'",
  "'7-13'",
  "'9+5'",
  "'m9+5'",
  "'7+5-9'",
  "'m7+5-9'",
  "'11'",
  ':m11',
  ':maj11',
  "'11+'",
  "'m11+'",
  "'13'",
  ':m13',
  ':add2',
  ':add4',
  ':add9',
  ':add11',
  ':add13',
  ':madd2',
  ':madd4',
  ':madd9',
  ':madd11',
  ':madd13',
  ':major',
  ':maj',
  ':M',
  ':minor',
  ':min',
  ':m',
  ':major7',
  ':dom7',
  "'7'",
  ':M7',
  ':minor7',
  ':m7',
  ':augmented',
  ':a',
  ':diminished',
  ':dim',
  ':i',
  ':diminished7',
  ':dim7',
  ':i7',
  ':halfdim',
  "'m7b5'",
  "'m7-5'",
}

M.tunings = {
  ':equal',
  ':just',
  ':pythagorean',
  ':meantone',
}

M.midi_params = {
  'sustain',
  'velocity',
  'vel',
  'velocity_f',
  'vel_f',
  'port',
  'channel',
}

M.example_names = {
  ':haunted',
  ':ambient_experiment',
  ':chord_inversions',
  ':filtered_dnb',
  ':fm_noise',
  ':jungle',
  ':ocean',
  ':reich_phase',
  ':acid',
  ':ambient',
  ':compus_beats',
  ':echo_drama',
  ':idm_breakbeat',
  ':tron_bike',
  ':wob_rhyth',
  ':bach',
  ':driving_pulse',
  ':monday_blues',
  ':rerezzed',
  ':square_skit',
  ':blimp_zones',
  ':blip_rhythm',
  ':shufflit',
  ':tilburg_2',
  ':time_machine',
  ':sonic_dreams',
}

M.random_sources = {
  ':white',
  ':light_pink',
  ':pink',
  ':dark_pink',
  ':perlin',
}

M.fx = {
  ':autotuner',
  ':band_eq',
  ':bitcrusher',
  ':bpf',
  ':compressor',
  ':distortion',
  ':echo',
  ':eq',
  ':flanger',
  ':gverb',
  ':hpf',
  ':ixi_techno',
  ':krush',
  ':level',
  ':lpf',
  ':mono',
  ':nbpf',
  ':nhpf',
  ':nlpf',
  ':normaliser',
  ':nrbpf',
  ':nrhpf',
  ':nrlpf',
  ':octaver',
  ':pan',
  ':panslicer',
  ':ping_pong',
  ':pitch_shift',
  ':rbpf',
  ':record',
  ':reverb',
  ':rhpf',
  ':ring_mod',
  ':rlpf',
  ':slicer',
  ':sound_out',
  ':sound_out_stereo',
  ':tanh',
  ':tremolo',
  ':vowel',
  ':whammy',
  ':wobble',
}

M.fx_params = {
  [':bitcrusher'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'sample_rate',
    'bits',
    'cutoff',
  },
  [':krush'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'gain',
    'cutoff',
    'res',
  },
  [':reverb'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'room',
    'damp',
  },
  [':gverb'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'spread',
    'damp',
    'pre_damp',
    'dry',
    'room',
    'release',
    'ref_level',
    'tail_level',
  },
  [':level'] = {
    'amp',
  },
  [':mono'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'pan',
  },
  [':autotuner'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'note',
    'formant_ratio',
  },
  [':echo'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'phase',
    'decay',
    'max_phase',
  },
  [':slicer'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'phase',
    'amp_min',
    'amp_max',
    'pulse_width',
    'phase_offset',
    'wave',
    'invert_wave',
    'probability',
    'prob_pos',
    'seed',
    'smooth',
    'smooth_up',
    'smooth_down',
  },
  [':panslicer'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'phase',
    'amp_min',
    'amp_max',
    'pulse_width',
    'phase_offset',
    'wave',
    'invert_wave',
    'probability',
    'prob_pos',
    'seed',
    'smooth',
    'smooth_up',
    'smooth_down',
    'pan_min',
    'pan_max',
  },
  [':wobble'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'phase',
    'cutoff_min',
    'cutoff_max',
    'res',
    'phase_offset',
    'wave',
    'invert_wave',
    'pulse_width',
    'filter',
    'probability',
    'prob_pos',
    'seed',
    'smooth',
    'smooth_up',
    'smooth_down',
  },
  [':ixi_techno'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'phase',
    'phase_offset',
    'cutoff_min',
    'cutoff_max',
    'res',
  },
  [':compressor'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'threshold',
    'clamp_time',
    'slope_above',
    'slope_below',
    'relax_time',
  },
  [':whammy'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'transpose',
    'max_delay_time',
    'deltime',
    'grainsize',
  },
  [':rlpf'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'cutoff',
    'res',
  },
  [':nrlpf'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'cutoff',
    'res',
  },
  [':rhpf'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'cutoff',
    'res',
  },
  [':nrhpf'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'cutoff',
    'res',
  },
  [':hpf'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'cutoff',
  },
  [':nhpf'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'cutoff',
  },
  [':lpf'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'cutoff',
  },
  [':nlpf'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'cutoff',
  },
  [':normaliser'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'level',
  },
  [':distortion'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'distort',
  },
  [':pan'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'pan',
  },
  [':bpf'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'centre',
    'res',
  },
  [':nbpf'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'centre',
    'res',
  },
  [':rbpf'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'centre',
    'res',
  },
  [':nrbpf'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'centre',
    'res',
  },
  [':band_eq'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'freq',
    'res',
    'db',
  },
  [':tanh'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'krunch',
  },
  [':pitch_shift'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'window_size',
    'pitch',
    'pitch_dis',
    'time_dis',
  },
  [':ring_mod'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'freq',
    'mod_amp',
  },
  [':octaver'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'super_amp',
    'sub_amp',
    'subsub_amp',
  },
  [':vowel'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'vowel_sound',
    'voice',
  },
  [':flanger'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'phase',
    'phase_offset',
    'wave',
    'invert_wave',
    'stereo_invert_wave',
    'delay',
    'max_delay',
    'depth',
    'decay',
    'feedback',
    'invert_flange',
  },
  [':eq'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'low_shelf',
    'low_shelf_note',
    'low_shelf_slope',
    'low',
    'low_note',
    'low_q',
    'mid',
    'mid_note',
    'mid_q',
    'high',
    'high_note',
    'high_q',
    'high_shelf',
    'high_shelf_note',
    'high_shelf_slope',
  },
  [':tremolo'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'phase',
    'phase_offset',
    'wave',
    'invert_wave',
    'depth',
  },
  [':record'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'buffer',
  },
  [':sound_out'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'output',
    'mode',
  },
  [':sound_out_stereo'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'output',
    'mode',
  },
  [':ping_pong'] = {
    'amp',
    'mix',
    'pre_mix',
    'pre_amp',
    'phase',
    'feedback',
    'max_phase',
    'pan_start',
  },
}

return M
