local M = {}

---@param bookmark Bookmarks.Bookmark
---@return string
function M.render_bookmark(bookmark)
  if vim.g.bookmarks_config.treeview and vim.g.bookmarks_config.treeview.bookmark_format then
    return vim.g.bookmarks_config.treeview.bookmark_format(bookmark)
  end
  return bookmark.name
    .. " ["
    .. bookmark.location.project_name
    .. "] "
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
