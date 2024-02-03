local repo = require("bookmarks.project-repo")

---@class Bookmarks.MarkParam
---@field name string

---@param param Bookmarks.MarkParam
local function mark(param)

	local cursor = vim.api.nvim_win_get_cursor(0)
	local filename = vim.fn.expand("%:p")
	---@type Bookmarks.Bookmark
	local bookmark = {
		name = param.name,
		location = { path = filename, line = cursor[0], col = cursor[1] },
		content = "content", -- TODO: check if current worktree's line content match this value
		githash = "githash", -- TODO: if not match, notify user with the githash.
	}

	local bookmark_lists = repo.get_domains()
	local active_bookmark_list = repo.find_or_set_active_bookmark_list(bookmark_lists)
	table.insert(active_bookmark_list.bookmarks, bookmark)

	local new_bookmark_lists = vim.tbl_filter(function(bookmark_list)
		---@cast bookmark_list Bookmarks.BookmarkList
		return bookmark_list.name ~= active_bookmark_list.name
	end, bookmark_lists)
	table.insert(new_bookmark_lists, active_bookmark_list)
	repo.write_domains(new_bookmark_lists)
end

---@class Bookmarks.NewListParam
---@field name string

---@param param Bookmarks.NewListParam
local function new_list(param) end

return {
	mark = mark,
	new_list = new_list,
}
