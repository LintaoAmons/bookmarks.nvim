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
---@field createdAt number -- os.time()

---@class Bookmarks.BookmarkList
---@field id string
---@field name string
---@field is_active boolean
---@field bookmarks Bookmarks.Bookmark[]

---@return Bookmarks.BookmarkList[]
local get_domains = function()
  -- TODO: add cache
	return json.read_or_init_json_file(vim.g.bookmarks_config.json_db_path)
end

---@param domain Bookmarks.BookmarkList[]
local write_domains = function(domain)
	json.write_json_file(domain, vim.g.bookmarks_config.json_db_path)
end

-- Function to generate an ID in the datetime format
local function generate_datetime_id()
	-- Get the current date and time in the desired format
	local datetime = os.date("%Y%m%d%H%M%S")

	-- Generate a random number (e.g., using math.random) and append it to the datetime
	local random_suffix = ""
	for _ = 1, 8 do
		random_suffix = random_suffix .. tostring(math.random(0, 9))
	end

	-- Concatenate the datetime and random suffix to create the ID
	local id = datetime .. random_suffix

	return id
end

---@param bookmark_lists? Bookmarks.BookmarkList[]
---@return Bookmarks.BookmarkList
local function find_or_set_active_bookmark_list(bookmark_lists)
	bookmark_lists = bookmark_lists or get_domains()
	local active_bookmark_list = nil

	-- Check if there's an active BookmarkList
	for _, bookmark_list in ipairs(bookmark_lists) do
		if bookmark_list.is_active then
			active_bookmark_list = bookmark_list
			break
		end
	end

	-- If no active BookmarkList was found, mark the first one as active
	if not active_bookmark_list and #bookmark_lists > 0 then
		bookmark_lists[1].is_active = true
		active_bookmark_list = bookmark_lists[1]
	end

	-- If there are no BookmarkLists, create a new one
	if not active_bookmark_list then
		active_bookmark_list = {
			id = generate_datetime_id(),
			name = "Default",
			is_active = true,
			bookmarks = {},
		}
		table.insert(bookmark_lists, active_bookmark_list)
	end

	return active_bookmark_list
end

return {
	get_domains = get_domains,
	write_domains = write_domains,
  generate_datetime_id = generate_datetime_id,
	find_or_set_active_bookmark_list = find_or_set_active_bookmark_list,
}
