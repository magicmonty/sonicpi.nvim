local status,cmp = pcall(require, "cmp")
cmp.setup.buffer({
  sources = {
    { name = "sonicpi" },
    { name = "nvim_lsp" },
    { name = "treesitter" },
    { name = "luasnip" },
    { name = "path" }
  }
})
