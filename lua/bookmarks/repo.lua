local json = require("bookmarks.json")

---@return Bookmarks.BookmarkList[]
local get_domains = function()
	-- TODO: add cache
	if vim.g.bookmarks_cache then
		return vim.g.bookmarks_cache
	end

	local ok, result = pcall(json.read_or_init_json_file, vim.g.bookmarks_config.json_db_path)
	if not ok then
		vim.notify(
			"Incorrect config, please check your config file at: "
				.. vim.g.bookmarks_config.json_db_path
				.. "\nor just remove it(all your bookmarks will disappear)",
			vim.log.levels.ERROR
		)
	end
	return result
end

---@param domain Bookmarks.BookmarkList[]
local write_domains = function(domain)
	vim.g.bookmarks_cache = domain
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

---@param bookmark_list_name string
---@param bookmark_lists? Bookmarks.BookmarkList[]
---@return Bookmarks.BookmarkList
local function must_find_bookmark_list_by_name(bookmark_list_name, bookmark_lists)
	bookmark_lists = bookmark_lists or get_domains()

	local found = vim.tbl_filter(function(bookmark_list)
		---@cast bookmark_list Bookmarks.BookmarkList
		return bookmark_list.name == bookmark_list_name
	end, bookmark_lists)

	if #found == 1 then
		return found[1]
	elseif #found == 0 then
		error("Can't found bookmark list by name ")
	else
		error(
			"More than one bookmark list have the name "
				.. bookmark_list_name
				.. ". Please clean your json db manually at "
				.. vim.g.bookmarks_config.json_db_path
		)
	end
end

-- pcall read method and display hint about correputed json file
return {
	get_domains = get_domains,
	write_domains = write_domains,
	generate_datetime_id = generate_datetime_id,
	find_or_set_active_bookmark_list = find_or_set_active_bookmark_list,
	must_find_bookmark_list_by_name = must_find_bookmark_list_by_name,
}
