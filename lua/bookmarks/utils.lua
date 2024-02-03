local function trim(str)
	return str:gsub("^%s+", ""):gsub("%s+$", "")
end
-- Function to shorten a file path
local function shorten_file_path(file_path)
	local parts = {}

	for part in string.gmatch(file_path, "[^/]+") do
		table.insert(parts, part)
	end

	if #parts > 1 then
		local filename = table.remove(parts) -- Remove and get the last part (filename)
		local shorten = vim.tbl_map(function(part)
			return string.sub(part, 1, 1)
		end, parts)

		return table.concat(shorten, "/") .. "/" .. filename
	else
		return file_path -- If there's only one part, return the original path
	end
end

return {
	trim = trim,
	shorten_file_path = shorten_file_path,
}
