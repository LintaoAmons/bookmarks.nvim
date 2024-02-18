local repo = require("bookmarks.repo")

---@param callback function
---@param opts? {prompt?: string}
local function pick_bookmark_list(callback, opts)
	local bookmark_lists = repo.get_domains()
	opts = opts or {}
	local prompt = opts.prompt or "Select bookmark list"

	vim.ui.select(bookmark_lists, {
		prompt = prompt,
		format_item = function(item)
			---@cast item Bookmarks.BookmarkList
			return item.name
		end,
	}, function(choice)
		---@cast choice Bookmarks.BookmarkList
		if not choice then
			return
		end
		callback(choice)
	end)
end

return {
	pick_bookmark_list = pick_bookmark_list,
}
