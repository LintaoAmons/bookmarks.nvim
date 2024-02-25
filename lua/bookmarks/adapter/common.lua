local utils = require("bookmarks.utils")

---@param bookmark Bookmarks.Bookmark
---@param bookmarks Bookmarks.Bookmark[]
local function format(bookmark, bookmarks)
	local max_len_name = 0
	local max_len_path = 0
	for _, bookmark in ipairs(bookmarks) do
		if #bookmark.name > max_len_name then
			max_len_name = #bookmark.name
		end
		local shorten_path = utils.shorten_file_path(bookmark.location.path)
		if #shorten_path > max_len_path then
			max_len_path = #shorten_path
		end
	end

	return string.format(
		"%-" .. max_len_name .. "s %-" .. max_len_path .. "s [%d, %d]: %s",
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
