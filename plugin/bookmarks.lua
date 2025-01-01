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
---@type Bookmarks.Config
vim.g.bookmarks_config = nil
---@type Bookmarks.TreeViewCtx
vim.g.bookmark_tree_view_ctx = nil
---@class Bookmarks.QueryCtx
vim.g.bookmarks_query_ctx = {
  ---@type PresentView
  view = nil,
  ---@type Bookmarks.Query
  query = {},
}


local bookmarks = require("bookmarks")

vim.api.nvim_create_user_command("BookmarksMark", bookmarks.toggle_mark, {
  desc = "Mark current line into active BookmarkList. Rename existing bookmark under cursor. Toggle it off if the new name is an empty string",
})

vim.api.nvim_create_user_command("BookmarksDesc", bookmarks.attach_desc, {
  desc = "Add description to the bookmark under cursor, if no bookmark, then mark it first",
})

vim.api.nvim_create_user_command(
  "BookmarksGoto",
  bookmarks.goto_bookmark,
  { desc = "Go to bookmark at current active BookmarkList" }
)

vim.api.nvim_create_user_command(
  "BookmarksGotoNext",
  bookmarks.goto_next_bookmark,
  { desc = "Go to next bookmark in line number order within the current active BookmarkList" }
)

vim.api.nvim_create_user_command(
  "BookmarksGotoPrev",
  bookmarks.goto_prev_bookmark,
  { desc = "Go to previous bookmark in line number order within the current active BookmarkList" }
)

vim.api.nvim_create_user_command(
  "BookmarksGotoNextInList",
  bookmarks.goto_next_list_bookmark,
  { desc = "Go to next bookmark within the current active BookmarkList" }
)

vim.api.nvim_create_user_command(
  "BookmarksGotoPrevInList",
  bookmarks.goto_prev_list_bookmark,
  { desc = "Go to previous bookmark within the current active BookmarkList" }
)

vim.api.nvim_create_user_command(
  "BookmarksGrep",
  bookmarks.grep_bookmarks,
  { desc = "Grep through the content of all bookmarked files" }
)

vim.api.nvim_create_user_command("BookmarksLists", bookmarks.bookmark_lists, { desc = "Pick a bookmark list" })

vim.api.nvim_create_user_command(
  "BookmarksNewList",
  bookmarks.create_bookmark_list,
  { desc = "Go to bookmark at current active BookmarkList" }
)

vim.api.nvim_create_user_command("BookmarksInfo", bookmarks.info, { desc = "Show bookmark.nvim plugin info" })

-- TODO: find a better way to do this
vim.api.nvim_create_user_command(
  "BookmarksInfoCurrentBookmark",
  bookmarks.bookmark_info,
  { desc = "Show bookmark.nvim plugin info" }
)

vim.api.nvim_create_user_command(
  "BookmarksCommands",
  bookmarks.commands,
  { desc = "Find bookmark commands and trigger it" }
)

vim.api.nvim_create_user_command("BookmarksTree", bookmarks.toggle_treeview, { desc = "browse bookmarks in tree view" })

vim.api.nvim_create_user_command("BookmarksQuery", bookmarks.query, { desc = "browse bookmarks in tree view" })

vim.api.nvim_create_user_command(
  "BookmarkRebindOrphanNode",
  bookmarks.rebind_orphan_node,
  { desc = "rebind the orphaned node to the root node" }
)
