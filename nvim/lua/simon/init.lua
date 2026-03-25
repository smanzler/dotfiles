require("simon.remap")

vim.opt.clipboard = "unnamedplus"
vim.g.netrw_bufsettings = 'noma nomod nu rnu nobl nowrap ro'
vim.opt.relativenumber = true

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true

vim.diagnostic.config({
  virtual_text = {
    spacing = 2,
    prefix = "●",
  },
})

vim.o.incsearch = true
vim.o.hlsearch = false
