---@class Bookmarks.Config
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
  },

  treeview = {
    ---@type fun(node: Bookmarks.Node): string | nil
    render_bookmark = function(node)
      -- Use different icons to indicate presence of description
      local icon = (node.description and #node.description > 0) and "●" or "○" -- Filled/Empty dot

      local filename = require("bookmarks.domain.location").get_file_name(node.location)
      local name = node.name .. ": " .. filename
      if node.name == "" then
        -- TODO: if no name, then use the first few char of the content, if also don't have content, then fallback to [Untitled]
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
      -- Example of a custom mapping
      ["<C-o>"] = {
        action = function()
          local ctx = require("bookmarks.tree.ctx").get_ctx()
          local line_no = vim.api.nvim_win_get_cursor(0)[1]
          local line_ctx = ctx.lines_ctx.lines_ctx[line_no]
          if line_ctx then
            local node = require("bookmarks.domain.repo").find_node(line_ctx.id)
            if node and node.location then
              vim.fn.jobstart({ "open", node.location.path }, { detach = true })
            end
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
