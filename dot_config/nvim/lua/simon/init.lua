require("simon.remap")
require("simon.tmux").setup_child()
require("simon.neogit").setup()

vim.g.clipboard = "osc52"
vim.opt.clipboard = "unnamedplus"

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.showtabline = 0

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
