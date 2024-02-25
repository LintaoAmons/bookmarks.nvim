local repo = require("bookmarks.repo")
local common = require("bookmarks.adapter.common")
local util = require("bookmarks.utils")

-- TODO: check dependencies firstly
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")

---@param callback fun(bookmark_list: Bookmarks.BookmarkList): nil
---@param opts? {prompt?: string}
local function pick_bookmark_list(callback, opts)
	local bookmark_lists = repo.get_domains()
	opts = opts or {}
	local prompt = opts.prompt or "Select bookmark list"

	pickers
		.new(opts, {
			prompt_title = prompt,
			finder = finders.new_table({
				results = bookmark_lists,
				---@param bookmark_list Bookmarks.BookmarkList
				entry_maker = function(bookmark_list)
					return {
						value = bookmark_list,
						display = bookmark_list.name,
						ordinal = bookmark_list.name,
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selected = action_state.get_selected_entry().value
					callback(selected)
				end)
				return true
			end,
		})
		:find()

	-- vim.ui.select(bookmark_lists, {
	-- 	prompt = prompt,
	-- 	format_item = function(item)
	-- 		---@cast item Bookmarks.BookmarkList
	-- 		return item.name
	-- 	end,
	-- }, function(choice)
	-- 	---@cast choice Bookmarks.BookmarkList
	-- 	if not choice then
	-- 		return
	-- 	end
	-- 	callback(choice)
	-- end)
end

---@param callback fun(bookmark: Bookmarks.Bookmark): nil
---@param opts? {prompt?: string, bookmark_list?: Bookmarks.BookmarkList}
local function pick_bookmark(callback, opts)
	opts = opts or {}
	local bookmark_list = opts.bookmark_list or repo.find_or_set_active_bookmark_list()
	local prompt = opts.prompt or ("Select bookmark from: " .. bookmark_list.name)

	local bookmarks = bookmark_list.bookmarks
	table.sort(bookmarks, function(a, b)
		return a.visited_at > b.visited_at
	end)

	pickers
		.new(opts, {
			prompt_title = prompt,
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
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selected = action_state.get_selected_entry().value
					callback(selected)
				end)
				return true
			end,
		})
		:find()

	-- TODO: fallback to vim.ui picker
	-- vim.ui.select(bookmarks, {
	-- 	prompt = prompt,
	-- 	format_item = function(item)
	-- 		return common.format(item, bookmarks)
	-- 	end,
	-- }, function(choice)
	-- 	---@cast choice Bookmarks.BookmarkList
	-- 	if not choice then
	-- 		return
	-- 	end
	-- 	callback(choice)
	-- end)
end

---@param cmds {name: string, callback: function}
---@param opts? {prompt?: string}
local function pick_commands(cmds, opts)
	opts = opts or {}
	local prompt = opts.prompt or "Select commands"

	pickers
		.new(opts, {
			prompt_title = prompt,
			finder = finders.new_table({
				results = cmds,
				---@param cmd Bookmark.Command
				---@return table
				entry_maker = function(cmd)
					return {
						value = cmd,
						display = cmd.name, -- TODO: add description
						ordinal = cmd.name,
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selected = action_state.get_selected_entry().value
					selected.callback()
				end)
				return true
			end,
		})
		:find()
end

return {
	pick_bookmark_list = pick_bookmark_list,
	pick_bookmark = pick_bookmark,
	pick_commands = pick_commands,
}
