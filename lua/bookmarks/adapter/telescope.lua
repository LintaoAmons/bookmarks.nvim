local repo = require("bookmarks.repo")
local common = require("bookmarks.adapter.common")
local api = require("bookmarks.api")

---@param opts? table
local goto_bookmark = function(opts)
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local actions = require("telescope.actions")
	local conf = require("telescope.config").values
	local action_state = require("telescope.actions.state")
	opts = opts or {}
	local active_bookmark_list = repo.find_or_set_active_bookmark_list()
	local bookmarks = active_bookmark_list.bookmarks

	pickers
		.new(opts, {
			prompt_title = "Current active list: " .. active_bookmark_list.name,
			finder = finders.new_table({
				results = bookmarks,
				---@param bookmark Bookmarks.Bookmark
				entry_maker = function(bookmark)
					local display = common.format(bookmark, bookmarks)
					return {
						value = bookmark,
						display = display,
						ordinal = display,
					}
				end,
			}),
			-- TODO: sort by visitedAt
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selected = action_state.get_selected_entry().value
					api.goto_bookmark(selected)
				end)
				return true
			end,
		})
		:find()
end

return {
	goto_bookmark = goto_bookmark,
}
