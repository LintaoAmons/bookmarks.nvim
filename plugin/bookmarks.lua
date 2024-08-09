if vim.fn.has("nvim-0.7.0") == 0 then
  vim.api.nvim_err_writeln("bookmarks.nvim requires at least nvim-0.7")
  return
end

-- make sure this file is loaded only once
if vim.g.loaded_bookmarks == 1 then
  return
end
vim.g.loaded_bookmarks = 1

-- all global variable should firstly declare at this place
vim.g.bookmarks_config = require("bookmarks.config").default_config
---@type Bookmarks.PopupWindowCtx
vim.g.bookmark_list_win_ctx = nil

require("bookmarks").setup()
require("bookmarks.sign").bookmark_sign_autocmd()
local adapter = require("bookmarks.adapter")
local api = require("bookmarks.api")

vim.api.nvim_create_user_command("BookmarksMark", adapter.mark, {
  desc = "Mark current line into active BookmarkList. Rename existing bookmark under cursor. Toggle it off if the new name is an empty string",
})
vim.api.nvim_create_user_command(
  "BookmarksGoto",
  adapter.goto_bookmark,
  { desc = "Go to bookmark at current active BookmarkList" }
)
vim.api.nvim_create_user_command(
  "BookmarksCommands",
  adapter.mark_commands,
  { desc = "Find and trigger a bookmark command." }
)
vim.api.nvim_create_user_command(
  "BookmarksGotoRecent",
  api.goto_last_visited_bookmark,
  { desc = "Go to latest visited/created Bookmark" }
)
vim.api.nvim_create_user_command(
  "BookmarksReload",
  api.helper.reload_bookmarks,
  { desc = "Clean the cache and resync the bookmarks jsonfile" }
)
vim.api.nvim_create_user_command("BookmarksEditJsonFile", api.helper.open_bookmarks_jsonfile, {
  desc = "An shortcut to edit bookmark jsonfile, remember BookmarksReload to clean the cache after you finish editing",
})
vim.api.nvim_create_user_command("BookmarksTree", api.tree.open_treeview, {})

vim.api.nvim_create_user_command("BookmarksCalibration", api.calibrate_bookmarks, {
  desc = "Calibrate the bookmarks jsonfile, this will change bookmarks line_no",
})
