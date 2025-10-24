---@class Bookmarks.Config.Backup
---@field enabled boolean Whether backup is enabled
---@field dir? string Directory to store backup files
---@field delay number Delay in minutes before nvim opened

---@class Bookmarks.Config.Navigation
---@field next_prev_wraparound_same_file boolean Enable/disable wrap-around when navigating

---@class Bookmarks.Config.Signs.Mark
---@field icon string Sign mark icon in the gutter
---@field color string Sign mark color
---@field line_bg string Sign line background color

---@class Bookmarks.Config.Signs
---@field mark Bookmarks.Config.Signs.Mark
---@field desc_format fun(bookmark: Bookmarks.Node): string Function to format bookmark description

---@class Bookmarks.Config.Picker
---@field sort_by string | fun(bookmarks: Bookmarks.Node[]): nil Sort logic for bookmark list
---@field entry_display? fun(bookmark: Bookmarks.Node, bookmarks: Bookmarks.Node[]): string Telescope entry display generation logic

---@class Bookmarks.Config.Calibrate
---@field auto_calibrate_cur_buf boolean Auto adjust window position when opening buffer
---@field show_calibrate_logs boolean Show calibration logs

---@alias Bookmarks.KeymapAction "quit" | "refresh" | "create_list" | "level_up" | "set_root" | "set_active" | "toggle" | "move_up" | "move_down" | "delete" | "rename" | "goto" | "cut" | "copy" | "paste" | "show_info" | "reverse" | "preview" | "add_to_aider" | "add_to_aider_read_only" | "drop_from_aider" | "show_help"

---@alias Bookmarks.KeymapCustomAction fun(node: Bookmarks.Node, info: Bookmarks.ActionNodeInfo): nil

---@class Bookmarks.Config.TreeView.Keymap.Entry
---@field action Bookmarks.KeymapAction | Bookmarks.KeymapCustomAction
---@field desc string

---@class Bookmarks.Config.TreeView.Highlights.ActiveList
---@field bg string Background color
---@field fg string Foreground color
---@field bold boolean Bold text

---@class Bookmarks.Config.TreeView.Highlights
---@field active_list Bookmarks.Config.TreeView.Highlights.ActiveList

---@class Bookmarks.Config.TreeView
---@field render_bookmark? fun(node: Bookmarks.Node): string | nil Custom function to render bookmarks
---@field highlights Bookmarks.Config.TreeView.Highlights Highlight configurations
---@field active_list_icon string Icon for active list
---@field keymap table<string, Bookmarks.Config.TreeView.Keymap.Entry> Keymap configurations
---@field window_split_dimension number Dimension of the window spawned for Treeview

---@class Bookmarks.Config.Query
---@field keymap table Keymap configurations

---@class Bookmarks.Config
---@field db_dir? string Directory to store the database file
---@field backup Bookmarks.Config.Backup Backup configurations
---@field navigation Bookmarks.Config.Navigation Navigation configurations
---@field signs Bookmarks.Config.Signs Sign configurations
---@field picker Bookmarks.Config.Picker Picker configurations
---@field calibrate Bookmarks.Config.Calibrate Calibration configurations
---@field commands table<string, function> Custom commands available in command picker
---@field treeview Bookmarks.Config.TreeView Tree view configurations
---@field query Bookmarks.Config.Query Query configurations

return {
  -- Directory to store the database file
  -- Default: vim.fn.stdpath("data")
  -- You can set a custom directory
  -- The plugin will:
  --   1. Create the directory if it doesn't exist
  --   2. Create `bookmarks.sqlite.db` inside this directory
  ---@type string?
  db_dir = nil, -- if nil, fallback to default `stdpath("data")`
  backup = {
    enabled = false,
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
    show_calibrate_logs = true,
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

    -- Example: Open BookmarksTree
    open_bookmark_tree = function()
      vim.cmd[[BookmarksTree]]
    end,
  },

  treeview = {
    ---@type fun(node: Bookmarks.Node): string | nil
    render_bookmark = nil,
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
      ["q"] = {
        action = "quit",
        desc = "Close the tree view window"
      },
      ["<ESC>"] = {
        action = "quit",
        desc = "Close the tree view window"
      },
      ["R"] = {
        action = "refresh",
        desc = "Reload and redraw the tree view"
      },
      ["a"] = {
        action = "create_list",
        desc = "Create a new list under the current node"
      },
      ["u"] = {
        action = "level_up",
        desc = "Navigate up one level in the tree hierarchy"
      },
      ["."] = {
        action = "set_root",
        desc = "Set current list as root of the tree view, also set as active list"
      },
      ["m"] = {
        action = "set_active",
        desc = "Set current list as the active list for bookmarks"
      },
      ["o"] = {
        action = "toggle",
        desc = "Toggle list expansion or go to bookmark location"
      },
      ["<localleader>k"] = {
        action = "move_up",
        desc = "Move current node up in the list"
      },
      ["<localleader>j"] = {
        action = "move_down",
        desc = "Move current node down in the list"
      },
      ["D"] = {
        action = "delete",
        desc = "Delete current node"
      },
      ["r"] = {
        action = "rename",
        desc = "Rename current node"
      },
      ["g"] = {
        action = "goto",
        desc = "Go to bookmark location in previous window"
      },
      ["x"] = {
        action = "cut",
        desc = "Cut node"
      },
      ["c"] = {
        action = "copy",
        desc = "Copy node"
      },
      ["p"] = {
        action = "paste",
        desc = "Paste node"
      },
      ["i"] = {
        action = "show_info",
        desc = "Show node info"
      },
      ["t"] = {
        action = "reverse",
        desc = "Reverse the order of nodes in the tree view"
      },
      ["P"] = {
        action = "preview",
        desc = "Preview bookmark content"
      },
      ["+"] = {
        action = "add_to_aider",
        desc = "Add to Aider"
      },
      ["="] = {
        action = "add_to_aider_read_only",
        desc = "Add to Aider as read-only"
      },
      ["-"] = {
        action = "drop_from_aider",
        desc = "Drop from Aider"
      },
      ["?"] = {
        action = "show_help",
        desc = "Show help panel with available keymaps"
      },
      -- Example of a custom mapping
      ["<C-o>"] = {
        ---@type Bookmarks.KeymapCustomAction
        action = function(node, info)
          if info.type == 'bookmark' then
            vim.system({'open', info.dirname}, { text = true })
          end
        end,
        desc = "Open the current node with system default software",
      },
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
}
