local Render = require("bookmarks.tree.render")
local Repo = require("bookmarks.domain.repo")
local Operate = require("bookmarks.tree.operate")

local M = {}

---@param opts {width: integer}
---@return integer
local function create_vsplit_with_width(opts)
  vim.cmd("vsplit")

  local new_win = vim.api.nvim_get_current_win()

  vim.api.nvim_win_set_width(new_win, opts.width)

  return new_win
end

local function register_local_shortcuts(buf)
  local keymap = vim.g.bookmarks_config.treeview.keymap
  if vim.g.bookmarks_config.treeview and vim.g.bookmarks_config.treeview.keymap then
    keymap = vim.g.bookmarks_config.treeview.keymap
  end

  local options = {
    noremap = true,
    silent = true,
    nowait = true,
    buffer = buf,
  }

  for action, keys in pairs(keymap) do
    if type(keys) == "string" then
      pcall(vim.keymap.set, { "v", "n" }, keys, Operate[action], options)
    elseif type(keys) == "table" then
      for _, k in ipairs(keys) do
        pcall(vim.keymap.set, { "v", "n" }, k, Operate[action], options)
      end
    end
  end
end

local function clean_tree_cache(buf)
  vim.b[buf]._bm_context = nil
  vim.b[buf]._bm_tree_cut = nil
end

---Toggle the tree view
--- FIXME: close tree view then reopen it will throw error
function M.toggle()
  local cur_window = vim.api.nvim_get_current_win()
  local ctx = vim.g.bookmark_tree_view_ctx
  local buf = ctx and ctx.buf or vim.api.nvim_create_buf(false, true)
  local win = ctx and ctx.win or create_vsplit_with_width({ width = 30 })
  local previous_window = ctx and ctx.previous_window
  register_local_shortcuts(buf)
  vim.g.bookmark_tree_view_ctx = {
    buf = buf,
    win = win,
    previous_window = cur_window,
  }

  -- Check if tree view exists
  if ctx and vim.api.nvim_win_is_valid(ctx.win) then
    if cur_window == ctx.win then
      -- Case: tree view is focused, close it
      vim.api.nvim_win_close(ctx.win, true)
      vim.g.bookmark_tree_view_ctx = nil
      -- Switch back to previous window if it's still valid
      if previous_window and vim.api.nvim_win_is_valid(previous_window) then
        vim.api.nvim_set_current_win(previous_window)
      end
      return
    else
      -- Case: tree view exists but not focused, switch to it
      vim.api.nvim_set_current_win(ctx.win)
      return
    end
  end

  local node = Repo.get_active_list()
  Render.refresh(node)
end

return M
