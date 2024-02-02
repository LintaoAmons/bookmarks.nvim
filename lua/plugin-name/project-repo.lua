local json = require("plugin-name.json")
---@class PluginName.Domain
---@field name string

---@return PluginName.Domain[]
local get_domains = function()
	return json.read_or_init_json_file(vim.g.plugin_name_config.projects_config_filepath)
end

---@param domain PluginName.Domain[]
local write_domains = function(domain)
	json.write_json_file(domain, vim.g.plugin_name_config.projects_config_filepath)
end

return {
	get_domains = get_domains,
	write_domains = write_domains,
}
