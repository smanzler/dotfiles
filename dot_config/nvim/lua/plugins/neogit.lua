return {
  "NeogitOrg/neogit",
  lazy = true,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "sindrets/diffview.nvim",
    "nvim-telescope/telescope.nvim",
  },
  cmd = "Neogit",
  keys = {
    {
      "<leader>gg",
      function()
        if require("simon.tmux").is_child() then
          vim.cmd("confirm qall")
        else
          vim.cmd("Neogit")
        end
      end,
      desc = "Show Neogit UI",
    },
  },
  opts = {
    kind = "replace",
  },
}
