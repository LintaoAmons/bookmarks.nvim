local utils = require("bookmarks.utils")

---@param bookmark Bookmarks.Bookmark
local function format(bookmark)
	print("DEBUGPRINT[1]: common.lua:4: bookmark=" .. vim.inspect(bookmark))

	return string.format(
		"%s %s [%d, %d]: %s",
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
