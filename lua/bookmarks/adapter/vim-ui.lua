local utils = require("bookmarks.utils")
local function add_list()
	vim.ui.input({ prompt = "Enter BookmarkList name" }, function(input)
		require("bookmarks.api").add_list({ name = input })
	end)
end

local function mark()
	vim.ui.input({ prompt = "Enter Bookmark name" }, function(input)
    local name = input or ""
    if utils.trim(input) == "" then
      -- TODO: name parse by the content
      name = "Default name"
    end

		require("bookmarks.api").mark({ name = name })
	end)
end

return {
	add_list = add_list,
  mark = mark,
}
