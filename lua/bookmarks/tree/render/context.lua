local domain = require("bookmarks.domain")
local render_bookmark = require("bookmarks.tree.render.bookmark")
local node_cls_type = require("bookmarks.domain.type")

local INTENT = "    "
local M = {}

---@class Bookmarks.LineContext
---@field deep number
---@field id number
---@field root_name string

---@class Bookmarks.TreeContext
---@field line_contexts Bookmarks.LineContext[]

---@param node Bookmarks.BookmarkList | Bookmarks.Bookmark
---@param deep number
---@return string
function M.render_context(node, deep)
  local node_type = domain.bookmark_list.get_value_type(node)
  local icon = node.collapse and "▸" or "▾"
  local book_icon = ""

  if node_type == node_cls_type.BOOKMARK then
    return string.rep(INTENT, deep) .. book_icon .. render_bookmark.render_bookmark(node)
  else
    local suffix = node.is_active and " *" or ""
    return string.rep(INTENT, deep) .. icon .. node.name .. suffix
  end
end

---@param node Bookmarks.Bookmark | Bookmarks.BookmarkList
---@param lines string[]
---@param line_contexts Bookmarks.LineContext[]
---@param deep number
function M.render_tree_recursive(node, lines, line_contexts, deep, root_id)
  local ctx = M.to_line_context(node.id, deep, root_id)
  local line = M.render_context(node, deep)
  table.insert(lines, line)
  table.insert(line_contexts, ctx)

  if node.collapse then
    return
  end

  if domain.bookmark_list.get_value_type(node) == domain.type.BOOKMARK then
    return
  end

  for _, child in ipairs(node.bookmarks) do
    M.render_tree_recursive(child, lines, line_contexts, deep + 1, root_id)
  end
end

---@param bookmark_lists Bookmarks.BookmarkList[]
---@return Bookmarks.TreeContext, string[]
function M.from_bookmark_lists(bookmark_lists)
  local lines = {}
  local line_contexts = {}

  table.sort(bookmark_lists, function(a, b)
    return a.name < b.name
  end)

  for _, bookmark_list in ipairs(bookmark_lists) do
    M.render_tree_recursive(bookmark_list, lines, line_contexts, 0, bookmark_list.name)
  end

  local ctx = {
    line_contexts = line_contexts,
  }

  return ctx, lines
end

---@param id string | number
---@param deep number
---@return Bookmarks.LineContext
function M.to_line_context(id, deep, root_name)
  return {
    id = id,
    deep = deep,
    root_name = root_name,
  }
end

return M
