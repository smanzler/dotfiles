local M = {}

local function current_view()
  local ok, lib = pcall(require, "diffview.lib")
  if not ok then
    return nil
  end

  local view = lib.get_current_view()
  if not view or type(view.infer_cur_file) ~= "function" then
    return nil
  end

  return view
end

function M.cursor_file()
  local view = current_view()
  if not view then
    return nil
  end

  local file = view:infer_cur_file()
  if not file or not file.absolute_path then
    return nil
  end

  local pos
  if file == view.cur_entry and view.cur_layout then
    local ok_win, win = pcall(function()
      return view.cur_layout:get_main_win()
    end)
    if ok_win and win and win.id and vim.api.nvim_win_is_valid(win.id) then
      pos = vim.api.nvim_win_get_cursor(win.id)
    end
  end

  return file.absolute_path, pos
end

function M.goto_cursor_file()
  local path, pos = M.cursor_file()
  if not path then
    vim.notify("No file under the cursor", vim.log.levels.WARN)
    return
  end

  vim.cmd("1tabnext")
  vim.cmd("tabonly")
  vim.cmd("edit " .. vim.fn.fnameescape(path))
  if pos then
    pcall(vim.api.nvim_win_set_cursor, 0, pos)
  end
end

return M
