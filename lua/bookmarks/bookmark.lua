local utils = require("bookmarks.utils")

---@class Bookmarks.Location
---@field path string
---@field line number
---@field col number

---@class Bookmarks.Bookmark
---@field id number -- pk, unique
---@field name string
---@field location Bookmarks.Location
---@field content string
---@field githash string
---@field created_at number -- pk, timestamp os.time() 
---@field visited_at number -- timestamp os.time()

-- TODO: remove id in bookmark_list, name as identifier

---@class Bookmarks.BookmarkList
---@field name string -- pk, unique
---@field is_active boolean
---@field bookmarks Bookmarks.Bookmark[]

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

---@param name? string
---@return Bookmarks.Bookmark
local function new_bookmark(name)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local filename = vim.fn.expand("%:p")
  local time = os.time()

	return {
    id = time,
		name = name or "",
		location = { path = filename, line = cursor[1], col = cursor[2] },
		content = vim.api.nvim_get_current_line(),
		githash = utils.get_current_version(),
		created_at = time,
		visited_at = time,
	}
end

---@param bookmark_lists Bookmarks.BookmarkList[]
---@return string[]
local function all_list_names(bookmark_lists)
	local result = {}
	for _, bookmark_list in ipairs(bookmark_lists) do
		table.insert(result, bookmark_list.name)
	end
	return result
end

-- TODO: turn those functions into instance methods
return {
	new_bookmark = new_bookmark,
	is_same_location = is_same_location,
	toggle_bookmarks = toggle_bookmarks,
	all_list_names = all_list_names,
}
