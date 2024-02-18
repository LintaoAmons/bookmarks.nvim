local repo = require("bookmarks.repo")
local api = require("bookmarks.api")
local vimui = require("bookmarks.adapter.vim-ui")
local picker = require("bookmarks.adapter.picker")

---@class Bookmark.Command
---@field name string
---@field short string
---@field callback function
---@field description? string

-- TODO: a helper function to generate this structure to markdown table to put into README file

---@type Bookmark.Command[]
local commands = {
	{
		name = "listnew",
		short = "ln",
		---@param parse_command Bookmark.MarkCommand
		callback = function(parse_command)
			local name
			if #parse_command.args ~= 0 then
				name = table.concat(parse_command.args, " ")
			else
				name = repo.generate_datetime_id()
			end
			local newlist = api.add_list({ name = name })
			api.mark({ name = "", list_name = newlist.name })
		end,
		description = "create a new BookmarkList and set it to active and mark current line into this BookmarkList",
	},
	{
		name = "listdelete",
		short = "ld",
		callback = function(_)
			local bookmark_lists = repo.get_domains()

			vim.ui.select(bookmark_lists, {
				prompt = "Select the bookmark list you want to delete",
				format_item = function(item)
					---@cast item Bookmarks.BookmarkList
					return item.name
				end,
			}, function(choice)
				---@cast choice Bookmarks.BookmarkList
				if not choice then
					return
				end
				vim.ui.input(
					{ prompt = "Are you sure you want to delete list" .. choice.name .. "? Y/N" },
					function(input)
						if input == "Y" then
							repo.delete_bookmark_list(choice.name)
							vim.notify(choice.name .. " list deleted")
						else
							vim.notify("deletion abort")
							return
						end
					end
				)
			end)
		end,
		description = "delete a bookmark list",
	},
	{
		name = "listsetactive",
		short = "lsa",
		callback = function(_)
			-- TODO: should I have this dependency in this module?
			vimui.set_active_list()
		end,
		description = "set a BookmarkList as active",
	},
	{
		name = "marktolist",
		short = "ml",
		---@param parse_command Bookmark.MarkCommand
		callback = function(parse_command)
			local name
			if #parse_command.args ~= 0 then
				name = table.concat(parse_command.args, " ")
			else
				name = ""
			end
			picker.pick_bookmark_list(function(choice)
				api.mark({
					name = name,
					list_name = choice.name,
				})
			end)
		end,
    description = "bookmark current line and add it to specific bookmark list"
	},
}

---@param parse_command Bookmark.MarkCommand
local function command_router(parse_command)
	for _, command in ipairs(commands) do
		if parse_command.command == command.name or parse_command.command == command.short then
			return command.callback(parse_command)
		end
	end
end

return {
	command_router = command_router,
}
