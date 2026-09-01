require("simon.remap")
require("simon.tmux").setup_child()
require("simon.lsp_idle").setup({ idle_minutes = 15 })

vim.g.clipboard = "osc52"
vim.opt.clipboard = "unnamedplus"

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.showtabline = 0

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true

vim.api.nvim_create_autocmd("VimResized", {
  callback = function()
    local tab = vim.api.nvim_get_current_tabpage()
    vim.cmd("noautocmd tabdo wincmd =")
    pcall(vim.api.nvim_set_current_tabpage, tab)
  end,
})

vim.diagnostic.config({
  virtual_text = {
    spacing = 2,
    prefix = "●",
  },
})
