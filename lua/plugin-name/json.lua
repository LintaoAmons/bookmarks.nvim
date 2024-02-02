---@param tbl table
---@param path string
local write_json_file = function(tbl, path)
	local content = vim.fn.json_encode(tbl) -- Encoding table to JSON string

	local file, err = io.open(path, "w")
	if not file then
		error("Could not open file: " .. err)
		return nil
	end

	file:write(content)
	file:close()
end

---@param path string
---@return table
local read_or_init_json_file = function(path)
	local file, _ = io.open(path, "r")
	if not file then
		write_json_file({}, path)
		return {}
	end

	local content = file:read("*a") -- Read the entire content
	file:close()

	return vim.fn.json_decode(content) or {}
end

return {
	write_json_file = write_json_file,
	read_or_init_json_file = read_or_init_json_file,
}
