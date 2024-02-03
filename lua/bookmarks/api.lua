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
		location = { path = filename, line = cursor[1], col = cursor[2] },
		content = "content", -- TODO: check if current worktree's line content match this value
		githash = "githash", -- TODO: if not match, notify user with the githash.
		createdAt = os.time(),
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
local function add_list(param)
	local bookmark_lists = repo.get_domains()
	local new_lists = vim.tbl_map(function(value)
		---@cast value Bookmarks.BookmarkList
		value.is_active = false
		return value
	end, bookmark_lists)

	---@type Bookmarks.BookmarkList
	local new_list = {
		name = param.name,
		id = repo.generate_datetime_id(),
		bookmarks = {},
		is_active = true,
	}

	table.insert(new_lists, new_list)
	repo.write_domains(new_lists)
end

---@param name string
local function set_active_list(name)
	local bookmark_lists = repo.get_domains()

	local updated = vim.tbl_map(function(value)
		---@cast value Bookmarks.BookmarkList
		if value.name == name then
			value.is_active = true
		else
			value.is_active = false
		end
		return value
	end, bookmark_lists)
	repo.write_domains(updated)
end

return {
	mark = mark,
	add_list = add_list,
	set_active_list = set_active_list,
}
