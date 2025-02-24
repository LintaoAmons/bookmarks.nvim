local default_config = require("bookmarks.default-config")

---Get the database file path from config or fallback
---@param db_dir? string Directory to store the database
---@return string
local function get_db_path(db_dir)
  if not db_dir then
    return vim.fn.stdpath("data") .. "/bookmarks.sqlite.db"
  end

  -- Validate/create directory
  if vim.fn.isdirectory(db_dir) == 0 then
    local ok = vim.fn.mkdir(db_dir, "p")
    if ok == 0 then
      error(string.format("Failed to create directory for database: %s", db_dir))
    end
  end

  -- Combine directory with default database filename
  return vim.fn.fnamemodify(db_dir .. "/bookmarks.sqlite.db", ":p")
end

---@param user_config? Bookmarks.Config
local setup = function(user_config)
  local cfg = vim.tbl_deep_extend("force", vim.g.bookmarks_config or default_config, user_config or {})
    or default_config
  vim.g.bookmarks_config = cfg

  require("bookmarks.domain.repo").setup(get_db_path(cfg.db_dir))
  require("bookmarks.sign").setup(cfg.signs)
  require("bookmarks.auto-cmd").setup()
  require("bookmarks.backup").setup(cfg, get_db_path(cfg.db_dir))
end

return {
  setup = setup,
  default_config = default_config,
}
