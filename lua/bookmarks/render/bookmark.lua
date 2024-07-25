local M = {}

---@param bookmark Bookmarks.Bookmark
---@return string
function M.render_bookmark(bookmark)
  return "["
    .. bookmark.location.project_name
    .. "] "
    .. bookmark.name
    .. ": "
    .. bookmark.location.relative_path
    .. " : "
    .. bookmark.content
end

---comment
---@param bookmarks Bookmarks.Bookmark[]
---@return string[]
function M.render(bookmarks)
  local result = {}
  for _, b in ipairs(bookmarks) do
    table.insert(result, M.render_bookmark(b))
  end

  return result
end

return M
