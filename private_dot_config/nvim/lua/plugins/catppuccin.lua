return {
  "catppuccin/nvim",
  name = "catppuccin",
  opts = {
    flavour = "mocha",
    transparent_background = true,
    custom_highlights = function(colors)
      return {
        NormalFloat = { bg = "none" },
        TelescopeBorder = { bg = "none" },
        LineNr = { fg = colors.subtext1 },
      }
    end,
    auto_integrations = true
  },
  lazy = false,
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin")
  end,
}
