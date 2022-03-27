local ls = require('luasnip')
local s = ls.s
local i = ls.insert_node
local fmt = require('luasnip.extras.fmt').fmt

return {
  s(
    'clocks',
    fmt(
      [[
        live_loop :clock, auto_cue: false do
          cue("clock" + (tick % 8).to_s).to_sym
          sleep 1
        end

        {}
      ]],
      { i(0) }
    )
  ),

  s(
    'echo',
    fmt(
      [[
        with_fx(:echo, decay: {}, mix: {}, phase: {}) do
          {}
        end
      ]],
      { i(1, '2.0'), i(2, '1.0'), i(3, '0.25'), i(0) }
    )
  ),

  s(
    'bd',
    fmt(
      [[
        live_loop :bd, sync: :clock1 do
          tick
          sample {} if spread({}, {}).look
          {}
          sleep 0.25
        end
      ]],
      { i(1, ':bd_haus'), i(2, '4'), i(3, '16'), i(0) }
    )
  ),

  s(
    'fx',
    fmt(
      [[
        with_fx(:{}) do
          {}
        end
      ]],
      { i(1), i(0) }
    )
  ),
  s(
    'll',
    fmt(
      [[
        live_loop :{} do
          {}
          sleep {}
        end
      ]],
      { i(1), i(0), i(2, '1') }
    )
  ),
  s(
    'llc',
    fmt(
      [[
        live_loop :{}, sync: :clock{} do
          {}
          sleep {}
        end
      ]],
      { i(1), i(2, '1'), i(0), i(3, '1') }
    )
  ),
  s(
    'reverb',
    fmt(
      [[
        with_fx(:reverb, room: {}, mix: {}, damp: {}) do
          {}
        end
      ]],
      { i(1, '0.8'), i(2, '0.7'), i(3, '0.5'), i(0) }
    )
  ),
}
