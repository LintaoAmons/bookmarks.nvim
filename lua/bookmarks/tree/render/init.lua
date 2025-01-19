local Context = require("bookmarks.tree.ctx")
local Repo = require("bookmarks.domain.repo")
local Highlight = require("bookmarks.tree.render.highlight")
local Location = require("bookmarks.domain.location")
local INTENT = "  "
local M = {}

---@class Bookmarks.LineCtx
---@field deep number
---@field id number
---@field root_id number -- TODO: remove it from line context

---@class Bookmarks.LinesCtx
---@field root_id number
---@field lines_ctx Bookmarks.LineCtx[]

--- TODO: bring back sort logics

---Sort nodes by their order value
---@param nodes Bookmarks.Node[]
---@param ascending boolean
---@return Bookmarks.Node[]
local function sort_nodes_by_order(nodes, ascending)
  table.sort(nodes, function(a, b)
    if ascending then
      return (a.order or 0) < (b.order or 0)
    else
      return (a.order or 0) > (b.order or 0)
    end
  end)
  return nodes
end

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
---@param active_list_id number
---@return string
local function render_list(node, active_list_id)
  local icon = vim.g.bookmarks_config.treeview.active_list_icon or "󰮔 "
  local fold_icon = node.is_expanded and "▾" or "▸"
  local active_indicator = (active_list_id and active_list_id == node.id) and icon or ""
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
local function render_context(node, deep, active_list_id)
  if node.type == "bookmark" then
    if vim.g.bookmarks_config.treeview.render_bookmark then
      return string.rep(INTENT, deep) .. vim.g.bookmarks_config.treeview.render_bookmark(node)
    end
    return string.rep(INTENT, deep) .. render_bookmark(node)
  else
    return string.rep(INTENT, deep) .. render_list(node, active_list_id)
  end
end

---@param node Bookmarks.Node
---@param lines string[]
---@param lines_ctx Bookmarks.LineCtx[]
---@param deep number
---@param root_id number
---@param active_list_id number
local function render_tree_recursive(node, lines, lines_ctx, deep, root_id, active_list_id)
  local ctx = to_line_context(node.id, deep, root_id)
  local line = render_context(node, deep, active_list_id)

  table.insert(lines, line)
  table.insert(lines_ctx, ctx)

  if node.type == "bookmark" then
    return
  end

  -- For list nodes, only render children if expanded
  if node.type == "list" and node.is_expanded then
    local tree_ctx = Context.get_ctx()
    local ascending = tree_ctx.sort_ascending or false
    local sorted_children = sort_nodes_by_order(node.children, ascending)
    for _, child in ipairs(sorted_children) do
      render_tree_recursive(child, lines, lines_ctx, deep + 1, root_id, active_list_id)
    end
  end
end

---Refresh the tree view
---@param root Bookmarks.Node
function M.refresh(root)
  local lines = {}
  local lines_ctx = {}
  local active_list = Repo.ensure_and_get_active_list()
  local active_list_id = active_list and active_list.id or 0

  render_tree_recursive(root, lines, lines_ctx, 0, root.id, active_list_id)

  local buf = vim.g.bookmark_tree_view_ctx.buf
  local win = vim.g.bookmark_tree_view_ctx.win
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_win_set_buf(win, buf)

  Context.set_lines_context({
    lines_ctx = lines_ctx,
    root_id = root.id,
  })

  -- Apply highlight in next tick to ensure buffer is ready
  vim.schedule(function()
    if active_list then
      Highlight.highlight_active_list(buf, active_list.id, lines_ctx)
    end
  end)
end

return M
