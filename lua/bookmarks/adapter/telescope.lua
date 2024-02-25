local api = require("bookmarks.api")
local picker = require("bookmarks.adapter.picker")

---@param opts? table
local goto_bookmark = function(opts)
	picker.pick_bookmark(function(choice)
		api.goto_bookmark(choice)
	end)
end

return {
	goto_bookmark = goto_bookmark,
}
