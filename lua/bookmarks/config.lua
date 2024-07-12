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
	require("bookmarks.utils").log(
		[[
> [!WARNING] Bookmarks.nvim
> Breaking change!
> Dev branch will be merged into main branch next Saturday!
> The json file db format will be changed. be sure you have your current bookmark db file
> Pin the version to v0.5.4 to avoid this error message
  ]],
		vim.log.levels.ERROR
	)
	local cfg = vim.tbl_deep_extend("force", vim.g.bookmarks_config or default_config, user_config or {})
		or default_config
	require("bookmarks.sign").setup(cfg.signs)
	vim.g.bookmarks_config = cfg
end

return {
	setup = setup,
}
