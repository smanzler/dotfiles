local M = {}

local function cursor_line(status, item)
  if not rawget(item, "diff") then
    return nil
  end

  local ok, jump = pcall(require, "neogit.lib.jump")
  if not ok then
    return nil
  end

  local line = status.buffer:cursor_line()
  for _, hunk in ipairs(item.diff.hunks) do
    if line >= hunk.first and line <= hunk.last then
      return jump.adjust_row(hunk.disk_from, line - hunk.first, hunk.lines, "-")
    end
  end
end

local function open_under_cursor()
  local ok, status = pcall(function()
    return require("neogit.buffers.status").instance()
  end)
  if not ok or not status then
    return
  end

  local item = status.buffer.ui:get_item_under_cursor()
  if item and item.absolute_path then
    require("simon.tmux").popup_edit(item.absolute_path, cursor_line(status, item), function()
      require("neogit").dispatch_refresh()
    end)
    return
  end

  local ref = status.buffer.ui:get_yankable_under_cursor()
  if ref then
    require("neogit.buffers.commit_view").new(ref):open()
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "NeogitStatus",
    callback = function(args)
      vim.keymap.set("n", "<cr>", open_under_cursor, {
        buffer = args.buf,
        nowait = true,
        desc = "Open the file under the cursor in a tmux popup",
      })
    end,
  })
end

return M
