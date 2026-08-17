local function edit()
  require("simon.diffview").edit_cursor_file()
end

local function overrides()
  return {
    { "n", "q",         "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
    { "n", "<leader>e", edit,                     { desc = "Edit the file under the cursor in a tmux popup" } },
  }
end

return {
  "sindrets/diffview.nvim",
  lazy = true,
  opts = {
    keymaps = {
      view = overrides(),
      file_panel = overrides(),
      file_history_panel = overrides(),
    },
  },
}
