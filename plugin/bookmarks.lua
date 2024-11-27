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
vim.g.bookmarks_config = nil

local bookmarks = require("bookmarks")
bookmarks.setup()

vim.api.nvim_create_user_command("BookmarksMark", bookmarks.toggle_mark, {
  desc = "Mark current line into active BookmarkList. Rename existing bookmark under cursor. Toggle it off if the new name is an empty string",
})

vim.api.nvim_create_user_command(
  "BookmarksGoto",
  bookmarks.goto_bookmark,
  { desc = "Go to bookmark at current active BookmarkList" }
)

vim.api.nvim_create_user_command("BookmarksLists", bookmarks.bookmark_lists, { desc = "Pick a bookmark list" })

vim.api.nvim_create_user_command(
  "BookmarksNewList",
  bookmarks.create_bookmark_list,
  { desc = "Go to bookmark at current active BookmarkList" }
)
