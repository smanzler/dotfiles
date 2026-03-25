return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local custom_codedark = require('lualine.themes.codedark')
    custom_codedark.normal.c.bg = 'None'

    require('lualine').setup({
      options = {
        theme = custom_codedark
      }
    })
  end
}
