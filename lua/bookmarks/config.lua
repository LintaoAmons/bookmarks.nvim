local default_config = {
	json_db_path = vim.fs.normalize(vim.fn.stdpath("config") .. "/bookmarks.db.json"),
}

vim.g.bookmarks_config = default_config

local setup = function(user_config)
	local previous_config = vim.g.bookmarks_config or default_config
	vim.g.bookmarks_config = vim.tbl_deep_extend("force", previous_config, user_config or {}) or default_config
end

return {
	setup = setup,
}
