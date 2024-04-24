---@class Bookmarks.Config
---@field sign { icon: string, highlight: string }
local default_config = {
	json_db_path = vim.fs.normalize(vim.fn.stdpath("config") .. "/bookmarks.db.json"),
	sign = {
		icon = "󰃁",
		highlight = "BookmarksNvimSign",
	},
}

vim.g.bookmarks_config = default_config

---@param user_config? Bookmarks.Config
local setup = function(user_config)
	local cfg = vim.tbl_deep_extend("force", vim.g.bookmarks_config or default_config, user_config or {})
		or default_config
	vim.fn.sign_define(cfg.sign.highlight, { text = cfg.sign.icon, texthl = cfg.sign.highlight })
	vim.api.nvim_set_hl(0, cfg.sign.highlight, { foreground = "grey" }) -- control the color of the sign
	vim.g.bookmarks_config = cfg
end

return {
	setup = setup,
}
