return {
  {
    'neovim/nvim-lspconfig',
    config = function()
      vim.lsp.config('denols', {
        root_markers = { 'deno.json', 'deno.jsonc' }
      })

      vim.lsp.config('vtsls', {
        root_markers = { 'package.json' },
        single_file_support = false
      })
    end
  }
}
