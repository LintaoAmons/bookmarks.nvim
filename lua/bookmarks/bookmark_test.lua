local bookmarks = require("bookmarks.bookmark")
local utils = require("bookmarks.utils")

local fixture = {
	---@type Bookmarks.BookmarkList
	bookmark_list = {
		id = "2024020411013822985471",
		name = "Default",
		is_active = true,
		bookmarks = {
			{
				created_at = 1707015831,
				name = "",
				location = {
					col = 21,
					path = "/Volumes/t7ex/Documents/oatnil/beta/bookmarks.nvim/lua/bookmarks/api.lua",
					line = 32,
				},
				githash = "e810b62",
				content = "line content",
				visited_at = 1707015831,
			},
		},
	},
	---@type Bookmarks.Bookmark
	bookmark = {
		created_at = 1707015831,
		name = "",
		location = {
			col = 21,
			path = "/Volumes/t7ex/Documents/oatnil/beta/bookmarks.nvim/lua/bookmarks/api.lua",
			line = 32,
		},
		githash = "e810b62",
		content = "  print('DEBUGPRINT[5]: api.lua:33: new_bookmark_lists=' .. vim.inspect(new_bookmark_lists))",
		visited_at = 1707015831,
	},
}

local function test_toggle_bookmarks()
	local new_bookmark = utils.deep_copy(fixture.bookmark)

	local result = bookmarks.toggle_bookmarks(fixture.bookmark_list, new_bookmark)

	return #result.bookmarks == 0
end

local function test_is_same_location()
	local b1 = utils.deep_copy(fixture.bookmark)
	local b2 = utils.deep_copy(fixture.bookmark)

	local result = bookmarks.is_same_location(b1, b2)

	return result == true
end

return {
	test_toggle_bookmarks = test_toggle_bookmarks,
	test_is_same_location = test_is_same_location,
}
