local M = {}
local bookmark = require("bookmarks.render.bookmark")

---comment
---@param lists Bookmarks.BookmarkList[]
---@return string[]
function M.render_lists(lists)
  local result = {}
  for _, l in ipairs(lists) do
    table.insert(result, l.name) -- TODO: show active list name in a highlight color
    for _, line in ipairs(bookmark.render(l.bookmarks)) do
      table.insert(result, line)
    end
  end

  return result
end

return M
