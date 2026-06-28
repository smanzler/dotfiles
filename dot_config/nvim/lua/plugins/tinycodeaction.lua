return {
  "rachartier/tiny-code-action.nvim",
  dependencies = {
    { "nvim-lua/plenary.nvim" },
  },
  event = "LspAttach",
  opts = {},
  config = function()
    local tiny = require("tiny-code-action")
    tiny.setup({
      picker = "buffer"
    })

    vim.keymap.set({ "n", "x" }, "<leader>ca", function()
      tiny.code_action()
    end, { noremap = true, silent = true })
  end
}
