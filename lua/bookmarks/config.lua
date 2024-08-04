---@class Bookmarks.Config
---@field json_db_path string
---@field signs Signs
---@field hooks? Bookmarks.Hook[]
local default_config = {
  -- where you want to put your bookmarks db file (a simple readable json file, which you can edit manually as well, dont forget run `BookmarksReload` command to clean the cache)
  json_db_path = vim.fs.normalize(vim.fn.stdpath("config") .. "/bookmarks.db.json"),
  -- This is how the sign looks.
  signs = {
    mark = { icon = "󰃁", color = "red", line_bg = "#572626" },
  },
  -- optional, backup the json db file when a new neovim session started and you try to mark a place
  -- you can find the file under the same folder
  enable_backup = true,
  -- treeview options
  treeview = {
    bookmark_format = function(bookmark)
      return bookmark.name
        .. " ["
        .. bookmark.location.project_name
        .. "] "
        .. bookmark.location.relative_path
        .. " : "
        .. bookmark.content
    end,
    keymap = {
      quit = { "q", "<ESC>" },
      refresh = "R",
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
  hooks = {
    {
      ---a sample hook that change the working directory when goto bookmark
      ---@param bookmark Bookmarks.Bookmark
      ---@param projects Bookmarks.Project[]
      callback = function(bookmark, projects)
        local project_path
        for _, p in ipairs(projects) do
          if p.name == bookmark.location.project_name then
            project_path = p.path
          end
        end
        if project_path then
          vim.cmd("cd " .. project_path)
        end
      end,
    },
  },
}

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
