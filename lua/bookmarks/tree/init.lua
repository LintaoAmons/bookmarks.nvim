local Render = require("bookmarks.tree.render")
local Repo = require("bookmarks.domain.repo")
local Operate = require("bookmarks.tree.operate")
local Highlight = require("bookmarks.tree.render.highlight")

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

local function setup_highlights()
  Highlight.setup_highlights()
end

---Toggle the tree view
function M.toggle()
  setup_highlights()

  local cur_window = vim.api.nvim_get_current_win()
  local ctx = vim.g.bookmark_tree_view_ctx

  -- Handle existing tree view
  if ctx and vim.api.nvim_win_is_valid(ctx.win) then
    if cur_window == ctx.win then
      -- Close tree view when it's focused
      vim.api.nvim_win_close(ctx.win, true)
      vim.g.bookmark_tree_view_ctx = nil

      -- Return to previous window if valid
      if ctx.previous_window and vim.api.nvim_win_is_valid(ctx.previous_window) then
        vim.api.nvim_set_current_win(ctx.previous_window)
      end
      return
    end

    -- Switch to existing tree view
    vim.api.nvim_set_current_win(ctx.win)
    return
  end

  -- Create new tree view
  local buf = vim.api.nvim_create_buf(false, true)
  -- Set the filetype for the buffer using the newer API
  vim.bo[buf].filetype = "BookmarksTree"
  local win = create_vsplit_with_width({ width = vim.g.bookmarks_config.treeview.window_split_dimension })

  register_local_shortcuts(buf)
  vim.g.bookmark_tree_view_ctx = {
    buf = buf,
    win = win,
    previous_window = cur_window,
  }

  local node = Repo.ensure_and_get_active_list()
  Render.refresh(node)
end

---refresh the tree view with a new root node
---@param root_id number
function M.refresh(root_id)
  Operate.refresh(root_id)
end

return M
