return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate',
  main = 'nvim-treesitter.config',
  opts = {
    ensure_installed = {
      "lua", "vim", "vimdoc", "javascript", "typescript", "tsx", "html", "css"
    },
    auto_install = true
  }
}
