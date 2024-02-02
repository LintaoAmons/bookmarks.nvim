local repo = require("bookmarks.project-repo")

---@class Bookmarks.MarkParam
---@field name string

---@param param Bookmarks.MarkParam
local function mark(param)
	-- 1. build bookmark
	local cursor = vim.api.nvim_win_get_cursor(0)
	local filename = vim.fn.expand("%:p")
	---@type Bookmarks.Bookmark
	local bookmark = {
		name = param.name,
		location = { path = filename, line = cursor[0], col = cursor[1] },
		content = "content", -- TODO: check if current worktree's line content match this value
		githash = "githash", -- TODO: if not match, notify user with the githash.
	}

	-- 2. get active bookmark list
	local active_bookmark_list = repo.find_or_set_active_bookmark_list()
  print('DEBUGPRINT[1]: api.lua:20: active_bookmark_list=' .. vim.inspect(active_bookmark_list))
	-- 3. insert into bookmark list
  print('DEBUGPRINT[2]: api.lua:23: active_bookmark_list.bookmarks=' .. vim.inspect(active_bookmark_list.bookmarks))
  active_bookmark_list.bookmarks = vim.tbl_deep_extend("force", active_bookmark_list.bookmarks, bookmark)
  print('DEBUGPRINT[3]: api.lua:22: active_bookmark_list.bookmarks=' .. vim.inspect(active_bookmark_list))

end

---@class Bookmarks.NewListParam
---@field name string

---@param param Bookmarks.NewListParam
local function new_list(param) end

return {
	mark = mark,
	new_list = new_list,
}
