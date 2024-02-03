local utils = require("bookmarks.utils")

---@param bookmark Bookmarks.Bookmark
---@param max_length integer
local function format(bookmark, max_length)
	return string.format(
		"%-" .. max_length .. "s %s [%d, %d]: %s",
		bookmark.name,
		utils.shorten_file_path(bookmark.location.path),
		bookmark.location.line,
		bookmark.location.col,
		bookmark.content
	)
end

return {
	format = format,
}
