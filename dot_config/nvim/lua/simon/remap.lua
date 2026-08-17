vim.g.mapleader = " "

vim.keymap.set("i", "jk", "<Esc>")

vim.keymap.set("n", "<leader>w", ":w<CR>")
vim.keymap.set("n", "<leader>nw", ":noautocmd w<CR>")

vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
