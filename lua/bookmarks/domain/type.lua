local M = {}

---@enum Bookmark.Type
M.type = {
  BOOKMARK = 1,
  BOOKMARK_LIST = 2,
}

---@param val Bookmarks.Node
---@return Bookmark.Type
function M.get_value_type(val)
  if val.bookmarks ~= nil then
    return M.type.BOOKMARK_LIST
  else
    return M.type.BOOKMARK
  end
end

return M
