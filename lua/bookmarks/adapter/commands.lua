local repo = require("bookmarks.repo")
local api = require("bookmarks.api")
local vimui = require("bookmarks.adapter.vim-ui")
local picker = require("bookmarks.adapter.picker")
local utils = require("bookmarks.utils")

---@class Bookmark.Command
---@field name string
---@field callback fun(): nil
---@field description? string

-- TODO: a helper function to generate this structure to markdown table to put into README file

---@type Bookmark.Command[]
local commands = {
	{
		name = "[List] new",
		callback = function()
			vim.ui.input({ prompt = "Enter the name of the new list: " }, function(input)
				local newlist = api.add_list({ name = input or tostring(os.time()) })
				api.mark({ name = "", list_name = newlist.name })
			end)
		end,
		description = "create a new BookmarkList and set it to active and mark current line into this BookmarkList",
	},
	{
		name = "[List] rename",
		callback = function()
			picker.pick_bookmark_list(function(bookmark_list)
				vim.ui.input({ prompt = "Enter new name: " }, function(input)
					if not input then
						return
					end
					api.rename_bookmark_list(input, bookmark_list.name)
					utils.log(
						"bookmark_list renamed from: " .. bookmark_list.name .. " to " .. input,
						vim.log.levels.INFO
					)
				end)
			end)
		end,
		description = "rename a BookmarkList",
	},
	{
		name = "[List] delete",
		callback = function()
			local bookmark_lists = repo.bookmark_list.read.find_all()

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
							repo.list.write.delete_bookmark_list(choice.name)
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
		name = "[List] set active",
		callback = function()
			-- TODO: should I have this dependency in this module?
			vimui.set_active_list()
		end,
		description = "set a BookmarkList as active",
	},
	{
		name = "[List] Browsing all lists",
		callback = function()
			picker.pick_bookmark_list(function(bookmark_list)
				picker.pick_bookmark(function(bookmark)
					api.goto_bookmark(bookmark, { open_method = "vsplit" })
				end, { bookmark_list = bookmark_list })
			end)
		end,
		description = "",
	},
	{
		name = "[Mark] mark to list",
		callback = function()
			picker.pick_bookmark_list(function(choice)
				api.mark({
					name = "", -- TODO: ask user to input name?
					list_name = choice.name,
				})
			end)
		end,
		description = "bookmark current line and add it to specific bookmark list",
	},
	{
		name = "[Mark] rename bookmark",
		callback = function()
			picker.pick_bookmark(function(bookmark)
				vim.ui.input({ prompt = "New name of the bookmark" }, function(input)
					api.rename_bookmark(bookmark.id, input or "")
				end)
			end)
		end,
		description = "rename selected bookmark",
	},
	{
		name = "[Mark] Browsing all marks",
		callback = function()
			picker.pick_bookmark(function(bookmark)
				api.goto_bookmark(bookmark, { open_method = "vsplit" })
			end, { all = true })
		end,
		description = "",
	},
}

return {
	commands = commands,
}
