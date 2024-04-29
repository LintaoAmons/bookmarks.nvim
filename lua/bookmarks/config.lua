---@class Bookmarks.Config
---@field signs Signs
local default_config = {
	json_db_path = vim.fs.normalize(vim.fn.stdpath("config") .. "/bookmarks.db.json"),
	signs = {
		mark = { icon = "󰃁", color = "grey" },
		-- annotation = { icon = "󰆉", color = "grey" }, -- TODO:
	},
}

vim.g.bookmarks_config = default_config

---@param user_config? Bookmarks.Config
local setup = function(user_config)
	local cfg = vim.tbl_deep_extend("force", vim.g.bookmarks_config or default_config, user_config or {})
		or default_config
	require("bookmarks.sign").setup(cfg.signs)
	vim.g.bookmarks_config = cfg
end

return {
	setup = setup,
}
