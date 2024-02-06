if vim.fn.has("nvim-0.7.0") == 0 then
	vim.api.nvim_err_writeln("bookmarks.nvim requires at least nvim-0.7")
	return
end

-- make sure this file is loaded only once
if vim.g.loaded_bookmarks == 1 then
	return
end
vim.g.loaded_bookmarks = 1

require("bookmarks").setup()
require("bookmarks.sign").bookmark_sign_autocmd()
local adapter = require("bookmarks.adapter")
local api = require("bookmarks.api")

vim.api.nvim_create_user_command("BookmarksAddList", adapter.add_list, {})
vim.api.nvim_create_user_command("BookmarksMark", adapter.mark, {})
vim.api.nvim_create_user_command("BookmarksMarkToList", adapter.mark_to_list, {})
vim.api.nvim_create_user_command("BookmarksGoto", adapter.goto_bookmark, {})
vim.api.nvim_create_user_command("BookmarksGotoRecent", api.goto_last_visited_bookmark, {})
vim.api.nvim_create_user_command("BookmarksSetActiveList", adapter.set_active_list, {})
