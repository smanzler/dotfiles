local function goto_file()
  require("simon.diffview").goto_cursor_file()
end

local function overrides()
  return {
    { "n", "q",         "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
  }
end

return {
  "sindrets/diffview.nvim",
  lazy = true,
  opts = {
    keymaps = {
      view = vim.list_extend(overrides(), {
        { "n", "<cr>", goto_file, { desc = "Open the file under the cursor in the first tabpage" } },
      }),
      file_panel = overrides(),
      file_history_panel = overrides(),
    },
  },
}
