local function add_list()
	require("bookmarks.adapter.vim-ui").add_list()
end

local function mark()
	require("bookmarks.adapter.vim-ui").mark()
end

local function mark_to_list()
	require("bookmarks.adapter.vim-ui").mark_to_list()
end

local function goto_bookmark()
	local success, _ = pcall(require, "telescope.pickers")
	if success then
		require("bookmarks.adapter.telescope").goto_bookmark()
	else
		require("bookmarks.adapter.vim-ui").goto_bookmark()
	end
end

local function set_active_list()
	require("bookmarks.adapter.vim-ui").set_active_list()
end

local function goto_bookmark_in_list()
	require("bookmarks.adapter.vim-ui").goto_bookmark_in_list()
end

return {
	add_list = add_list,
	mark = mark,
	goto_bookmark = goto_bookmark,
	goto_bookmark_in_list = goto_bookmark_in_list,
	set_active_list = set_active_list,
  mark_to_list = mark_to_list,
}
