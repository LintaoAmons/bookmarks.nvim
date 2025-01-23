---@class Bookmarks.Config
local default_config = {
  -- Directory to store the database file
  -- Default: vim.fn.stdpath("data")
  -- You can set a custom directory
  -- The plugin will:
  --   1. Create the directory if it doesn't exist
  --   2. Create `bookmarks.sqlite.db` inside this directory
  ---@type string?
  db_dir = nil, -- if nil, fallback to default `stdpath("data")`
  backup = {
    enabled = true,
    -- Directory to store backup files
    -- Default: vim.fn.stdpath("data").."/bookmarks.backup"
    -- You can set a custom directory
    ---@type string?
    dir = nil,
    delay = 5, -- Delay in minutes before nvim opened, no back will be created if nvim earlier than the actually backup time
  },

  -- Navigation configurations
  navigation = {
    -- Enable/disable wrap-around when navigating to next/previous bookmark within the same file
    next_prev_wraparound_same_file = true,
  },

  -- Bookmarks sign configurations
  signs = {
    -- Sign mark icon and color in the gutter
    mark = {
      icon = "󰃁",
      color = "red",
      line_bg = "#572626",
    },
    desc_format = function(bookmark)
      ---@cast bookmark Bookmarks.Node
      return bookmark.order .. ": " .. bookmark.name
    end,
  },

  -- Telescope/picker configurations
  picker = {
    -- Sort logic for bookmark list
    -- Built-in options: "last_visited", "created_date"
    -- Or provide custom sort function
    ---@type: string | fun(bookmarks: Bookmarks.Node[]): nil
    sort_by = "last_visited",
    -- telescope entry display generation logic
    ---@type: nil | fun(bookmark: Bookmarks.Node, bookmarks: Bookmarks.Node[]): string
    entry_display = nil,
  },

  -- Bookmark position calibration
  calibrate = {
    -- Auto adjust window position when opening buffer
    auto_calibrate_cur_buf = true,
  },

  -- Custom commands available in command picker
  ---@type table<string, function>
  commands = {
    -- Example: Add warning bookmark
    mark_warning = function()
      vim.ui.input({ prompt = "[Warn Bookmark]" }, function(input)
        if input then
          local Service = require("bookmarks.domain.service")
          Service.toggle_mark("⚠ " .. input)
          require("bookmarks.sign").safe_refresh_signs()
        end
      end)
    end,

    -- Example: Create list for current project
    create_project_list = function()
      local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
      local Service = require("bookmarks.domain.service")
      local new_list = Service.create_list(project_name)
      Service.set_active_list(new_list.id)
      require("bookmarks.sign").safe_refresh_signs()
    end,
  },

  ---@type { keymap: { [string]: string|string[] } }
  treeview = {
    ---@type fun(node: Bookmarks.Node): string | nil
    render_bookmark = function(node)
      -- Use different icons to indicate presence of description
      local icon = (node.description and #node.description > 0) and "●" or "○" -- Filled/Empty dot

      local filename = require("bookmarks.domain.location").get_file_name(node.location)
      local name = node.name .. ": " .. filename
      if node.name == "" then
        name = "[Untitled]"
      end

      return icon .. " " .. name
    end,
    highlights = {
      active_list = {
        bg = "#2C323C",
        fg = "#ffffff",
        bold = true,
      },
    },
    active_list_icon = "󰮔 ",
    -- stylua: ignore start
    keymap = {
      quit = { "q", "<ESC>" },      -- Close the tree view window and return to previous window
      refresh = "R",                -- Reload and redraw the tree view
      create_list = "a",            -- Create a new list under the current node
      level_up = "u",               -- Navigate up one level in the tree hierarchy
      set_root = ".",               -- Set current list as root of the tree view, also set as active list
      set_active = "m",             -- Set current list as the active list for bookmarks
      toggle = "o",                 -- Toggle list expansion or go to bookmark location
      move_up = "<localleader>k",   -- Move current node up in the list
      move_down = "<localleader>j", -- Move current node down in the list
      delete = "D",                 -- Delete current node
      rename = "r",                 -- Rename current node
      goto = "g",                   -- Go to bookmark location in previous window
      cut = "x",                    -- Cut node
      copy = "c",                   -- Copy node
      paste = "p",                  -- Paste node
      show_info = "i",              -- Show node info
      reverse = "t",                -- Reverse the order of nodes in the tree view
    },
    -- Dimension of the window spawned for Treeview
    window_split_dimension = 30,
    -- stylua: ignore end
  },

  query = {
    -- Stylua: ignore start
    -- TOOD: allow user to customize keymap
    keymap = {},
    -- stylua: ignore end
  },

  codecompanion = {
    enabled = false,
  },
}

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
  require("bookmarks.codecompanion").setup()
end

return {
  setup = setup,
  default_config = default_config,
}
