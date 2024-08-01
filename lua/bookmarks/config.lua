---@class Bookmarks.Config
---@field json_db_path string
---@field signs Signs
---@field hooks? Bookmarks.Hook[]
local default_config = {
  json_db_path = vim.fs.normalize(vim.fn.stdpath("config") .. "/bookmarks.db.json"),
  signs = {
    mark = { icon = "󰃁", color = "grey", line_bg= "#572626"},
    -- annotation = { icon = "󰆉", color = "grey" }, -- TODO:
  },
  enable_backup = true,
  -- do whatever you like by hooks
  hooks = {},
}

vim.g.bookmarks_config = default_config

---@param user_config? Bookmarks.Config
local setup = function(user_config)
  local cfg = vim.tbl_deep_extend("force", vim.g.bookmarks_config or default_config, user_config or {})
    or default_config
  vim.g.bookmarks_config = cfg

  require("bookmarks.sign").setup(cfg.signs)
end

return {
  setup = setup,
}
