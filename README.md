# sonicpi.nvim

This is a neovim plugin for [Sonic Pi](http://sonic-pi.net).

It's implemented solely in lua. It features a dynamic completion engine, powered by [nvim-cmp].
Help texts and completions are parsed from Sonic Pi's server code.

## Installation

You will need at least version 0.6 of neovim with lua support and [nvim-cmp].
Use your preferred package/plugin manager to install this plugin.
With [packer.nvim](http://github.com/wbthomason/packer.nvim), this looks like:

```lua
use({
  'magicmonty/sonicpi.nvim',
  config = function()
    require('sonicpi').setup({
      server_dir = '/opt/sonic-pi/app/server'
    })
  end,
  requires = {¬
    'hrdh7th/nvim-cmp',
    'kyazdani42/nvim-web-devicons'
  }
})
```

You have to set the directory to the Sonic Pi server, so that the plugin can read the documentation and language arguments for the completion engine.

### LSP setup
If you want to use the LSP, then install solargraph correctly and add the following to the `on_init` callback of your lsp config:

```lua
local function on_init(client)
  ...

  require('sonicpi').lsp_on_init(client, { server_dir = '/opt/sonic-pi/app/server' })
end
```

### CMP setup

If you want to use the completion engine, then you have to add the `sonicpi` source to your config:

```lua
require('cmp').setup({
  ...

  sources = {
    ...
    { name = 'sonicpi' }
    ...
  },
})
```

### Luasnip
This plugin has support for Luasnip. If you have luasnip istalled, then a selection of predefined snippets will be available.

Currently the following snippets are available:
- `clocks` -> makes a live loop, which acts as a selection of clocks where you can synchronize to
- `ll` -> makes a live loop
- `llc` -> makes a live loop, which synchronizes to a specific clock cue
- `bd` -> makes a live loop with a four on the floor base drum pattern
- `fx` -> makes a generic `with_fx` block
- `echo` -> makes a `with_fx` block with echo settings
- `reverb` -> makes a `with_fx` block with reverb settings

[nvim-cmp]: https://github.com/hrs7th/nvim-cmp
