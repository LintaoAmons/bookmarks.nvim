---@class Bookmarks.TreeViewCtx
---@field buf integer tree view buffer
---@field win integer tree view window
---@field previous_window integer previous window
---@field lines_ctx Bookmarks.LinesCtx
---@field store {node: Bookmarks.Node|nil, operation: "cut"|"copy"|nil} store for cut/copy operations

local M = {}

---Sets bookmark tree view buffer context
---@param buf number Buffer number
function M.set_buffer(buf)
  local ctx = vim.g.bookmark_tree_view_ctx or {}
  ctx.buf = buf
  vim.g.bookmark_tree_view_ctx = ctx
end

---Sets bookmark tree view window context
---@param win number Window number
function M.set_window(win)
  local ctx = vim.g.bookmark_tree_view_ctx or {}
  ctx.win = win
  vim.g.bookmark_tree_view_ctx = ctx
end

---Sets bookmark tree view previous window context
---@param previous_window number Previous window number
function M.set_previous_window(previous_window)
  local ctx = vim.g.bookmark_tree_view_ctx or {}
  ctx.previous_window = previous_window
  vim.g.bookmark_tree_view_ctx = ctx
end

---Sets bookmark tree view lines context
---@param lines_ctx Bookmarks.LinesCtx Lines context
function M.set_lines_context(lines_ctx)
  local ctx = vim.g.bookmark_tree_view_ctx or {}
  ctx.lines_ctx = lines_ctx
  vim.g.bookmark_tree_view_ctx = ctx
end

---@return Bookmarks.TreeViewCtx
function M.get_ctx()
  return vim.g.bookmark_tree_view_ctx
end

---Sets store in tree view context
---@param node Bookmarks.Node
---@param operation "cut"|"copy"
function M.set_store(node, operation)
  local ctx = vim.g.bookmark_tree_view_ctx or {}
  ctx.store = {
    node = node,
    operation = operation
  }
  vim.g.bookmark_tree_view_ctx = ctx
end

function M.clear()
  vim.g.bookmark_tree_view_ctx = nil
end

return M
