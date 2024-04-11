function generate_markdown_table(commands)
	local max_name_length = 0
	local max_description_length = 0

	-- Calculate the maximum length of name and description
	for _, command in ipairs(commands) do
		max_name_length = math.max(max_name_length, #command.name)
		max_description_length = math.max(max_description_length, #(command.description or ""))
	end

	local markdown_content = "| Command"
		.. string.rep(" ", max_name_length - 6)
		.. " | Description"
		.. string.rep(" ", max_description_length - 11)
		.. " |\n"
	markdown_content = markdown_content
		.. "| "
		.. string.rep("-", max_name_length)
		.. " | "
		.. string.rep("-", max_description_length)
		.. " |\n"

	for _, command in ipairs(commands) do
		local name_format = "%-" .. max_name_length .. "s"
		local description_format = "%-" .. max_description_length .. "s"
		local name = string.format(name_format, command.name)
		local description = command.description or ""
		description = string.format(description_format, description)
		markdown_content = markdown_content .. "| " .. name .. " | " .. description .. " |\n"
	end

	return markdown_content
end


return {
	generate_markdown_table = function()
		vim.print(generate_markdown_table(require("bookmarks.adapter.commands").commands))
	end,
}
