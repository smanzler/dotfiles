local M = {}

M.child_env = "NVIM_POPUP_EDIT"

function M.is_child()
  return vim.env[M.child_env] ~= nil
end

function M.setup_child()
  if not M.is_child() then
    return
  end

  vim.keymap.set("n", "q", "<cmd>confirm qall<cr>", { desc = "Close the popup" })
  vim.keymap.set("n", "Q", "q", { desc = "Record macro" })
end

function M.popup_edit(path, line)
  if not vim.env.TMUX then
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    if line then
      pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
    end
    return
  end

  local editor = { "nvim" }
  if line then
    table.insert(editor, "+" .. line)
  end
  table.insert(editor, path)

  vim.fn.jobstart({
    "tmux", "popup",
    "-E",
    "-w", "90%",
    "-h", "90%",
    "-b", "rounded",
    "-T", " " .. vim.fn.fnamemodify(path, ":t") .. " ",
    "-s", "bg=default",
    "-S", "bg=default,fg=#cba6f7",
    "-d", vim.fn.getcwd(),
    "-e", M.child_env .. "=1",
    table.concat(vim.tbl_map(vim.fn.shellescape, editor), " "),
  }, {
    on_exit = function()
      vim.schedule(function()
        vim.cmd("checktime")
        pcall(function()
          require("diffview.actions").refresh_files()
        end)
        pcall(function()
          require("neogit").dispatch_refresh()
        end)
      end)
    end,
  })
end

return M
