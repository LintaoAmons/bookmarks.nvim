local utils = require("bookmarks.utils")

---@param bookmark Bookmarks.Bookmark
---@param bookmarks Bookmarks.Bookmark[]
local function format(bookmark, bookmarks)
  local max_len_listname = 0
  local max_len_name = 0
  local max_len_path = 0

  for _, b in ipairs(bookmarks) do
    if b.listname and #b.listname > max_len_listname then
      max_len_listname = #b.listname
    end

    if #b.name > max_len_name then
      max_len_name = #b.name
    end

    local shorten_path = b.location.project_name .. "/" .. utils.shorten_file_path(b.location.relative_path)
    if #shorten_path > max_len_path then
      max_len_path = #shorten_path
    end
  end

  return string.format(
    "%-" .. max_len_listname .. "s %-" .. max_len_name .. "s %-" .. max_len_path .. "s",
    bookmark.listname or "",
    bookmark.name,
    bookmark.location.project_name .. "/" .. utils.shorten_file_path(bookmark.location.relative_path)
  )
end

return {
  format = format,
}
