local json = require("bookmarks.json")

---@class Bookmarks.Location
---@field path string
---@field line number
---@field col number

---@class Bookmarks.Bookmark
---@field name string
---@field location Bookmarks.Location
---@field content string
---@field githash string

---@class Bookmarks.BookmarkList
---@field id string
---@field name string
---@field bookmarks Bookmarks.Bookmark[]
--
---@return Bookmarks.BookmarkList[]
local get_domains = function()
	return json.read_or_init_json_file(vim.g.bookmarks_config.projects_config_filepath)
end

---@param domain Bookmarks.BookmarkList[]
local write_domains = function(domain)
	json.write_json_file(domain, vim.g.bookmarks_config.projects_config_filepath)
end

return {
	get_domains = get_domains,
	write_domains = write_domains,
}
