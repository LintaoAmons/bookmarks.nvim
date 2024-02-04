local function add_list()
	require("bookmarks.adapter.vim-ui").add_list()
end

local function mark()
	require("bookmarks.adapter.vim-ui").mark()
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

return {
	add_list = add_list,
	mark = mark,
	goto_bookmark = goto_bookmark,
	set_active_list = set_active_list,
}
