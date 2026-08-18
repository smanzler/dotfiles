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

  local line
  if file == view.cur_entry and view.cur_layout then
    local ok_win, win = pcall(function()
      return view.cur_layout:get_main_win()
    end)
    if ok_win and win and win.id and vim.api.nvim_win_is_valid(win.id) then
      line = vim.api.nvim_win_get_cursor(win.id)[1]
    end
  end

  return file.absolute_path, line
end

function M.refresh_and_restore(view)
  if type(view.update_files) ~= "function" then
    return
  end

  local restore = view.cur_entry and view.cur_entry.path

  view:update_files(function(err)
    if err or not restore or type(view.set_file_by_path) ~= "function" then
      return
    end

    vim.schedule(function()
      if view:is_cur_tabpage() then
        view:set_file_by_path(restore, false, true)
      end
    end)
  end)
end

function M.edit_cursor_file()
  local view = current_view()
  if not view then
    return
  end

  local path, line = M.cursor_file()
  if not path then
    vim.notify("No file under the cursor", vim.log.levels.WARN)
    return
  end

  require("simon.tmux").popup_edit(path, line, function()
    M.refresh_and_restore(view)
  end)
end

return M
