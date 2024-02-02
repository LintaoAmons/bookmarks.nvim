local function api_name()
	vim.print(vim.g.plugin_name_config.json_db_path)
end

return {
	api_name = api_name,
}
