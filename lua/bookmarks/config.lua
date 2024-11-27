---@class Bookmarks.Config
local default_config = {
  -- where you want to put your bookmarks db file (sqlite3 db file)
  db_path = vim.fs.normalize(vim.fn.stdpath("data") .. "/bookmarks.db.json"),
  -- This is how the sign looks.
  signs = {
    mark = { icon = "󰃁", color = "red", line_bg = "#572626" },
    desc_format = function(desc)
      return desc
    end,
  },
  picker = {
    -- choose built-in sort logic by name: string, find all the sort logics in `bookmarks.adapter.sort-logic`
    -- or custom sort logic: function(bookmarks: Bookmarks.Bookmark[]): nil
    sort_by = "last_visited",
  },
  calibrate = {
    -- when you open buffer, calibrate the window position
    auto_calibrate_cur_buf = true,
  },
}

---@param user_config? Bookmarks.Config
local setup = function(user_config)
  local cfg = vim.tbl_deep_extend("force", vim.g.bookmarks_config or default_config, user_config or {})
    or default_config
  vim.g.bookmarks_config = cfg

  require("bookmarks.domain.repo").setup()
  require("bookmarks.sign").setup(cfg.signs)
  require("bookmarks.auto-cmd").setup()
end

return {
  setup = setup,
  default_config = default_config,
}
