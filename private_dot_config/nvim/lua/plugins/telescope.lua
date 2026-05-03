return {
  'nvim-telescope/telescope.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  },
  keys = function()
    local builtin = require("telescope.builtin")
    return {
      { "<leader>ff", builtin.find_files, desc = "Find Files" },
      { "<leader>fg", builtin.git_files,  desc = "Git Files" },
      { "<leader>fs", builtin.live_grep,  desc = "Live Grep" },
      { "<leader>fb", builtin.buffers,    desc = "Buffers" },
      {
        "<leader>fd",
        function()
          builtin.fd({ find_command = { "fd", "-t=d" } })
        end,
        desc = "Find Directories"
      },
      { "<leader>gs", builtin.lsp_definitions, desc = "Find definition" }
    }
  end,
}
