local utils = require("bookmarks.utils")

---@class Bookmarks.Location
---@field path string
---@field line number
---@field col number

---@class Bookmarks.Bookmark
---@field name string
---@field location Bookmarks.Location
---@field content string
---@field githash string
---@field createdAt number

---@class Bookmarks.BookmarkList
---@field id string
---@field name string
---@field is_active boolean
---@field bookmarks Bookmarks.Bookmark[]
--

---@param b1 Bookmarks.Bookmark
---@param b2 Bookmarks.Bookmark
---@return boolean
local function is_same_location(b1, b2)
	if b1.location.path == b2.location.path and b1.location.line == b2.location.line then
		return true
	end
	return false
end

---@param bookmark_list Bookmarks.BookmarkList
---@param bookmark Bookmarks.Bookmark
---@return boolean
local function contains_bookmark(bookmark_list, bookmark)
	for _, b in ipairs(bookmark_list.bookmarks) do
		---@cast b Bookmarks.Bookmark
		if is_same_location(b, bookmark) then
			return true
		end
	end

	return false
end

---@param bookmark_list Bookmarks.BookmarkList
---@param new_bookmark Bookmarks.Bookmark
---@return Bookmarks.BookmarkList
local function toggle_bookmarks(bookmark_list, new_bookmark)
	local updated_bookmark_list = utils.deep_copy(bookmark_list)

	if contains_bookmark(updated_bookmark_list, new_bookmark) then
		local new_bookmarks = vim.tbl_filter(function(b)
			---@cast b Bookmarks.Bookmark
			return not is_same_location(b, new_bookmark)
		end, updated_bookmark_list.bookmarks)
		updated_bookmark_list.bookmarks = new_bookmarks
	else
		table.insert(updated_bookmark_list.bookmarks, new_bookmark)
	end

	return updated_bookmark_list
end

return {
	is_same_location = is_same_location,
	toggle_bookmarks = toggle_bookmarks,
}
