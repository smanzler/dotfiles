-- Stop LSP clients for worktrees you have stopped looking at, and bring them
-- back when you return.
--
-- Why: this monorepo (3.5GB, ~42 yarn workspaces, ~3800 TS files) legitimately
-- needs a big tsserver per workspace root you navigate into, and vtsls launches
-- each with --max-old-space-size=3072. Capping that just OOM-loops the server, so
-- the only safe lever is fewer servers ALIVE AT ONCE rather than smaller ones.
-- Measured: closing two background worktrees' editors freed ~4.7GB and took swap
-- from 15.6GB to 10.9GB.
--
-- Buffers visible in a window are never touched, so the worktree you are actually
-- working in keeps its full server.
--
-- :LspIdle        show clients, their idle time, and what would be stopped
-- :LspIdleNow     stop everything eligible right now
-- :LspIdleOff     disable the timer for this session

local M = {}

local defaults = {
  idle_minutes = 15,   -- stop a client after all its buffers idle this long
  check_seconds = 60,  -- how often to sweep
  -- servers worth reclaiming; small ones are not worth the reattach cost
  servers = { vtsls = true, eslint = true, tailwindcss = true, basedpyright = true },
}

local cfg = {}
local last_seen = {}   -- bufnr -> uv.now() ms
local timer = nil
local enabled = true

local function now() return vim.uv.now() end

local function touch(bufnr)
  if bufnr and bufnr > 0 then last_seen[bufnr] = now() end
end

-- A buffer currently displayed in any window is "in use" regardless of timers.
local function is_visible(bufnr)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == bufnr then
      return true
    end
  end
  return false
end

-- Idle ms for a client = the most recently used of its attached buffers.
-- Returns nil when the client should be left alone.
local function client_idle_ms(client)
  if not cfg.servers[client.name] then return nil end
  local newest, any = nil, false
  for bufnr in pairs(client.attached_buffers or {}) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      any = true
      if is_visible(bufnr) then return nil end          -- on screen: keep
      if vim.bo[bufnr].modified then return nil end     -- unsaved: keep
      local seen = last_seen[bufnr] or 0
      if newest == nil or seen > newest then newest = seen end
    end
  end
  if not any then return nil end
  return now() - (newest or 0)
end

function M.report()
  local threshold = cfg.idle_minutes * 60 * 1000
  local clients = vim.lsp.get_clients()
  if #clients == 0 then print("lsp-idle: no clients running") return end
  print(("lsp-idle: %d client(s), threshold %dm, timer %s")
    :format(#clients, cfg.idle_minutes, enabled and "on" or "off"))
  for _, c in ipairs(clients) do
    local idle = client_idle_ms(c)
    local nbufs = vim.tbl_count(c.attached_buffers or {})
    local root = c.config and c.config.root_dir or c.root_dir or "?"
    root = tostring(root):gsub(vim.env.HOME or "~", "~")
    if idle == nil then
      print(("  %-14s %-2d bufs  in use / pinned      %s"):format(c.name, nbufs, root))
    else
      print(("  %-14s %-2d bufs  idle %5.1fm %s  %s"):format(
        c.name, nbufs, idle / 60000,
        idle > threshold and "-> WOULD STOP" or "              ", root))
    end
  end
end

function M.sweep(force)
  local threshold = cfg.idle_minutes * 60 * 1000
  local stopped = {}
  for _, c in ipairs(vim.lsp.get_clients()) do
    local idle = client_idle_ms(c)
    if idle and (force or idle > threshold) then
      table.insert(stopped, c.name)
      -- graceful shutdown; a fresh one starts on demand (see BufEnter below).
      -- nvim 0.12 deprecates vim.lsp.stop_client in favour of the client method.
      if type(c.stop) == "function" then c:stop(false) else vim.lsp.stop_client(c.id, false) end
    end
  end
  if #stopped > 0 then
    vim.notify("lsp-idle: stopped " .. table.concat(stopped, ", "), vim.log.levels.INFO)
  end
  return stopped
end

-- Reattach: vim.lsp.enable() (which mason-lspconfig uses) hooks FileType, and that
-- does not re-fire for an already-loaded buffer. Re-emit it explicitly so returning
-- to a worktree transparently brings its server back.
local function maybe_reattach(bufnr)
  if vim.bo[bufnr].buftype ~= "" then return end
  local ft = vim.bo[bufnr].filetype
  if ft == nil or ft == "" then return end
  if #vim.lsp.get_clients({ bufnr = bufnr }) > 0 then return end
  pcall(vim.api.nvim_exec_autocmds, "FileType", { buffer = bufnr, modeline = false })
end

function M.setup(opts)
  cfg = vim.tbl_deep_extend("force", defaults, opts or {})

  local group = vim.api.nvim_create_augroup("SimonLspIdle", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "InsertEnter" }, {
    group = group,
    callback = function(ev)
      touch(ev.buf)
      maybe_reattach(ev.buf)
    end,
  })
  vim.api.nvim_create_autocmd({ "CursorHold", "BufWritePost" }, {
    group = group,
    callback = function(ev) touch(ev.buf) end,
  })
  vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    callback = function(ev) last_seen[ev.buf] = nil end,
  })

  -- seed: whatever is open at startup counts as just-used
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) then touch(b) end
  end

  timer = vim.uv.new_timer()
  timer:start(cfg.check_seconds * 1000, cfg.check_seconds * 1000,
    vim.schedule_wrap(function() if enabled then M.sweep(false) end end))

  vim.api.nvim_create_user_command("LspIdle", function() M.report() end,
    { desc = "Show LSP clients and their idle time" })
  vim.api.nvim_create_user_command("LspIdleNow", function() M.sweep(true) end,
    { desc = "Stop all eligible idle LSP clients now" })
  vim.api.nvim_create_user_command("LspIdleOff", function()
    enabled = false
    vim.notify("lsp-idle: timer disabled for this session", vim.log.levels.WARN)
  end, { desc = "Disable idle LSP stopping for this session" })
end

return M
