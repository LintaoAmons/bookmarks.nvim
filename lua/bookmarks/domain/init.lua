
local location = require("bookmarks.domain.location")
local bookmark = require("bookmarks.domain.bookmark")
local bookmark_list = require("bookmarks.domain.bookmark_list")
local project = require("bookmarks.domain.project")

local BookmarkModule = {
  -- TODO: remove this method from domain module
  all_list_names = function(bookmark_lists)
    local result = {}
    for _, bl in ipairs(bookmark_lists) do
        table.insert(result, bl.name)
    end
    return result
  end,
  location = location,
  bookmark = bookmark,
  bookmark_list = bookmark_list,
  project = project,
}

return BookmarkModule
