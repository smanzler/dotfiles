return {
    'nvim-telescope/telescope.nvim', version = '*',
    dependencies = {
        'nvim-lua/plenary.nvim',
	{ 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    keys = function()
      local builtin = require("telescope.builtin")
      return {
        { "<C-f>", builtin.find_files, desc = "Find Files" },
        { "<leader>ff", builtin.git_files, desc = "Git Files" },
        { "<leader>fg", builtin.live_grep, desc = "Live Grep" },
      }
    end,
}
