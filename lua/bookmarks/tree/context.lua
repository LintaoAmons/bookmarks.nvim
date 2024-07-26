local tree_node = require("bookmarks.tree.node")
local domain = require("bookmarks.bookmark")
local render_bookmark = require("bookmarks.render.bookmark")

local INTENT = "    "
local M = {}

local context_impl = {}

---@class Bookmarks.LineContext
---@field deep number
---@field id number

---@class Bookmarks.TreeContext
---@field line_contexts Bookmarks.LineContext[]

---@param bookmark_lists Bookmarks.BookmarkList[]
---@param id string | number
---@return Bookmarks.Bookmark
function M.get_bookmark(bookmark_lists, id)
  for _, bookmark_list in ipairs(bookmark_lists) do
    for _, bookmark in ipairs(bookmark_list.bookmarks) do
      if bookmark.id == id then
        return bookmark
      end
    end
  end
end

---@param bookmark_lists Bookmarks.BookmarkList[]
---@param node Bookmarks.TreeNode
---@param deep number
---@return string
function M.render_context(bookmark_lists, node, deep)
  local icon = node.collapse and "▾" or "▸"
  local book_icon = "𝔹"
  if node.type == tree_node.NODE_TYPE.ROOT then
    return "<root>"
  elseif node.type == tree_node.NODE_TYPE.BOOKMARK_LIST then
    return string.rep(INTENT, deep) .. icon .. node.id
  elseif node.type == tree_node.NODE_TYPE.BOOKMARK then
    local bookmark = M.get_bookmark(bookmark_lists, node.id)
    return string.rep(INTENT, deep) .. book_icon .. render_bookmark.render_bookmark(bookmark)
  elseif node.type == tree_node.NODE_TYPE.FOLDER then
    return string.rep(INTENT, deep) .. icon .. node.name
  end

  return ""
end

---@param node Bookmarks.TreeNode
---@param lines string[]
---@param line_contexts Bookmarks.LineContext[]
---@param deep number
---@param bls Bookmarks.BookmarkList[]
function M.render_tree_recursive(node, lines, line_contexts, deep, bls)
  local ctx = M.to_line_context(node.id, deep)
  local line = M.render_context(bls, node, deep)
  table.insert(lines, line)
  table.insert(line_contexts, ctx)

  if not node.collapse then
    return
  end

  for _, child in ipairs(node.children) do
    M.render_tree_recursive(child, lines, line_contexts, deep + 1, bls)
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
    local bookmark_list_node = domain.bookmark_list.get_tree(bookmark_list)
    M.render_tree_recursive(bookmark_list_node, lines, line_contexts, 0, bookmark_lists)
  end

  local ctx = {
    line_contexts = line_contexts,
  }

  return ctx, lines
end

---@param id string | number
---@param deep number
---@return Bookmarks.LineContext
function M.to_line_context(id, deep)
  return {
    id = id,
    deep = deep,
  }
end

return M
