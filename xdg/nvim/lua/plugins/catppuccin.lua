return {
  "catppuccin/nvim",
  name = "catppuccin",
  opts = { flavour = "mocha" },
  lazy = false,
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin")
  end,
}
