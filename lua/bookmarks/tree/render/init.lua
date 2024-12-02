local Context = require("bookmarks.tree.ctx")
local Highlight = require("bookmarks.tree.render.highlight")
local INTENT = "  "
local M = {}

---@class Bookmarks.LineCtx
---@field deep number
---@field id number
---@field root_id number -- TODO: remove it from line context

---@class Bookmarks.LinesCtx
---@field root_id number
---@field lines_ctx Bookmarks.LineCtx[]

-- TODO: allow user define their own render function
--
---@param node Bookmarks.Node
---@return string
local function render_bookmark(node)
  local book_icon = "◉"

  local name = node.name
  if node.name == "" then
    name = "[Untitled]"
  end

  return book_icon .. " " .. name
end

---@param node Bookmarks.Node
---@return string
local function render_list(node)
  local fold_icon = node.is_expanded and "▾" or "▸"
  local active_list = require("bookmarks.domain.repo").get_active_list()
  local active_indicator = (active_list and active_list.id == node.id) and "󰮔 " or "" -- Point
  return fold_icon .. " " .. active_indicator .. node.name
end

---@param id number
---@param deep number
---@param root_id number
---@return Bookmarks.LineCtx
local function to_line_context(id, deep, root_id)
  return {
    id = id,
    deep = deep,
    root_id = root_id,
  }
end

---@param node Bookmarks.Node
---@param deep number
---@return string
function M.render_context(node, deep)
  if node.type == "bookmark" then
    return string.rep(INTENT, deep) .. render_bookmark(node)
  else
    return string.rep(INTENT, deep) .. render_list(node)
  end
end

---@param node Bookmarks.Node
---@param lines string[]
---@param lines_ctx Bookmarks.LineCtx[]
---@param deep number
---@param root_id number
function M.render_tree_recursive(node, lines, lines_ctx, deep, root_id)
  local ctx = to_line_context(node.id, deep, root_id)
  local line = M.render_context(node, deep)
  table.insert(lines, line)
  table.insert(lines_ctx, ctx)

  if node.type == "bookmark" then
    return
  end

  -- For list nodes, only render children if expanded
  if node.type == "list" and node.is_expanded then
    for _, child in ipairs(node.children) do
      M.render_tree_recursive(child, lines, lines_ctx, deep + 1, root_id)
    end
  end
end

---Refresh the tree view
---@param root Bookmarks.Node
function M.refresh(root)
  local lines = {}
  local lines_ctx = {}

  M.render_tree_recursive(root, lines, lines_ctx, 0, root.id)

  local buf = vim.g.bookmark_tree_view_ctx.buf
  local win = vim.g.bookmark_tree_view_ctx.win
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_win_set_buf(win, buf)

  Context.set_lines_context({
    lines_ctx = lines_ctx,
    root_id = root.id,
  })

  -- Highlight active list
  local active_list = require("bookmarks.domain.repo").get_active_list()
  if active_list then
    Highlight.highlight_active_list(buf, active_list.id, lines_ctx)
  end
end

return M
