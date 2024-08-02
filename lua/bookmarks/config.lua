---@class Bookmarks.Config
---@field json_db_path string
---@field signs Signs
---@field hooks? Bookmarks.Hook[]
local default_config = {
  json_db_path = vim.fs.normalize(vim.fn.stdpath("config") .. "/bookmarks.db.json"),
  signs = {
    mark = { icon = "󰃁", color = "grey", line_bg = "#572626" },
  },
  enable_backup = true,
  treeview = {
    bookmark_formt = function(bookmark)
      return "[" .. bookmark.location.project_name .. "] " .. bookmark.name .. ": " .. bookmark.location.relative_path
    end,
    keymap = {
      quit = { "q", "<ESC>" },
      create_folder = "a",
      tree_cut = "x",
      tree_paste = "p",
      collapse = "o",
      delete = "d",
      active = "s",
      copy = "c",
    },
  },
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
  default_config = default_config,
}
