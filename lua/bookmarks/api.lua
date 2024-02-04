local repo = require("bookmarks.repo")
local sign = require("bookmarks.sign")
local domain = require("bookmarks.bookmark")

---@class Bookmarks.MarkParam
---@field name string

---@param param Bookmarks.MarkParam
local function mark(param)
	local bookmark = domain.new_bookmark(param.name)
	local bookmark_lists = repo.get_domains()
	local active_bookmark_list = repo.find_or_set_active_bookmark_list(bookmark_lists)
  local updated_bookmark_list = domain.toggle_bookmarks(active_bookmark_list, bookmark)

	local new_bookmark_lists = vim.tbl_filter(function(bookmark_list)
		---@cast bookmark_list Bookmarks.BookmarkList
		return bookmark_list.name ~= updated_bookmark_list.name
	end, bookmark_lists)
	table.insert(new_bookmark_lists, updated_bookmark_list)

	repo.write_domains(new_bookmark_lists)

	sign.refresh_signs()
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

  sign.refresh_signs()
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

  sign.refresh_signs()
end

return {
	mark = mark,
	add_list = add_list,
	set_active_list = set_active_list,
}
