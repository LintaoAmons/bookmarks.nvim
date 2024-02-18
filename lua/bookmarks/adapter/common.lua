local utils = require("bookmarks.utils")

---@param bookmark Bookmarks.Bookmark
---@param bookmarks Bookmarks.Bookmark[]
local function format(bookmark, bookmarks)
	local max_len_name = 0
	local max_len_path = 0
	for _, bookmark in ipairs(bookmarks) do
		if #bookmark.name > max_len_name then
			max_len_name = #bookmark.name
		end
		local shorten_path = utils.shorten_file_path(bookmark.location.path)
		if #shorten_path > max_len_path then
			max_len_path = #shorten_path
		end
	end

	return string.format(
		"%-" .. max_len_name .. "s %-" .. max_len_path .. "s [%d, %d]: %s",
		bookmark.name,
		utils.shorten_file_path(bookmark.location.path),
		bookmark.location.line,
		bookmark.location.col,
		bookmark.content
	)
end

---@param input string
---@return Bookmark.MarkCommand
local function parse_command(input)
	local is_command = vim.startswith(input, "!")
	if not is_command then
		return {
			is_command = false,
		}
	end

	local command = string.gsub(input, "!", "")
	local splited = vim.split(command, " ", { trimempty = true })
	if #splited == 0 then
		error("empty command")
	end

	return {
		is_command = is_command,
		command = splited[1],
		args = { unpack(splited, 2) },
	}
end

return {
	format = format,
  parse_command = parse_command
}
