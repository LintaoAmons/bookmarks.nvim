local repo = require("bookmarks.repo")
local utils = require("bookmarks.utils")
local common = require("bookmarks.adapter.common")
local api = require("bookmarks.api")

local function add_list()
	vim.ui.input({ prompt = "Enter BookmarkList name" }, function(input)
		input = input or utils.trim(input)
		if not input or input == "" then
			return vim.notify("Require a valid name")
		end
		require("bookmarks.api").add_list({ name = input })
	end)
end

---@class Bookmark.MarkCommand
---@field is_command boolean
---@field command? string
---@field args? string[]

local function mark()
	vim.ui.input({ prompt = "Enter Bookmark name" }, function(input)
		local parse_command = common.parse_command(input)
		if parse_command.is_command then
			if parse_command.command == "newlist" or parse_command.command == "nl" then
				local name
				if #parse_command.args ~= 0 then
					name = table.concat(parse_command.args, " ")
				else
					name = repo.generate_datetime_id()
				end
				local newlist = api.add_list({ name = name })
				api.mark({ name = "", list_name = newlist.name })
				return
			end
		end
		require("bookmarks.api").mark({ name = (input or "") })
	end)
end

local function mark_to_list()
	local bookmark_lists = repo.get_domains()
	vim.ui.input({ prompt = "Enter Bookmark name" }, function(name)
		vim.ui.select(bookmark_lists, {
			prompt = "select the bookmark list to put in",
			---@param bookmark_list Bookmarks.BookmarkList
			---@return string
			format_item = function(bookmark_list)
				return bookmark_list.name
			end,
		}, function(bookmark_list)
			---@cast bookmark_list  Bookmarks.BookmarkList
			if not bookmark_list then
				return
			end

			local param = {
				name = name or "",
				list_name = bookmark_list.name,
			}
			api.mark(param)
		end)
	end)
end

local function goto_bookmark()
	local bookmark_list = repo.find_or_set_active_bookmark_list()

	table.sort(bookmark_list.bookmarks, function(a, b)
		return a.createdAt > b.createdAt
	end)

	vim.ui.select(bookmark_list.bookmarks, {
		prompt = "Selete bookmark from active list: " .. bookmark_list.name,
		format_item = function(item)
			---@cast item Bookmarks.Bookmark
			return common.format(item, bookmark_list.bookmarks)
		end,
	}, function(choice)
		if not choice then
			return
		end
		---@cast choice Bookmarks.Bookmark
		api.goto_bookmark(choice)
	end)
end

local function set_active_list()
	local bookmark_lists = repo.get_domains()

	vim.ui.select(bookmark_lists, {
		prompt = "Set active list",
		format_item = function(item)
			---@cast item Bookmarks.BookmarkList
			if item.is_active then
				return "Active: " .. item.name
			end
			return item.name
		end,
	}, function(choice)
		if not choice then
			return
		end
		---@cast choice Bookmarks.BookmarkList
		api.set_active_list(choice.name)
	end)
end

-- TODO: Telescope version
local function goto_bookmark_in_list()
	local bookmark_lists = repo.get_domains()
	vim.ui.select(bookmark_lists, {
		prompt = "select the bookmark list",
		format_item = function(bookmark_list)
			return bookmark_list.name
		end,
	}, function(bookmark_list)
		---@cast bookmark_list  Bookmarks.BookmarkList
		if not bookmark_list then
			return
		end

		vim.ui.select(bookmark_list.bookmarks, {
			prompt = "Select bookmark",
			format_item = function(bookmark)
				return common.format(bookmark, bookmark_list.bookmarks)
			end,
		}, function(choice)
			if not choice then
				return
			end
			api.goto_bookmark(choice)
		end)
	end)
end

return {
	add_list = add_list,
	mark = mark,
	mark_to_list = mark_to_list,
	goto_bookmark = goto_bookmark,
	set_active_list = set_active_list,
	goto_bookmark_in_list = goto_bookmark_in_list,
}
