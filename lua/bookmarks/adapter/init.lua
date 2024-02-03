local function add_list()
	require("bookmarks.adapter.vim-ui").add_list()
end

local function mark()
  
	require("bookmarks.adapter.vim-ui").mark()
end

return {
	add_list = add_list,
  mark = mark
}
