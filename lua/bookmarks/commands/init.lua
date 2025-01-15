-- local Window = require("bookmarks.utils.window")
local Service = require("bookmarks.domain.service")
local Node = require("bookmarks.domain.node")
local Location = require("bookmarks.domain.location")
local Sign = require("bookmarks.sign")
local Tree = require("bookmarks.tree")
-- local Node = require("bookmarks.node")

local M = {}

-- Get user commands from config
local function get_user_commands()
  local cfg = vim.g.bookmarks_config or {}
  return cfg.commands or {}
end

-- Merge built-in and user commands
M.get_all_commands = function()
  local commands = {}
  -- Add built-in commands
  for name, func in pairs(M) do
    if type(func) == "function" and name ~= "get_all_commands" then
      commands[name] = func
    end
  end
  -- Add user commands
  for name, func in pairs(get_user_commands()) do
    commands[name] = func
  end
  return commands
end

M.new_list = function()
  vim.ui.input({ prompt = "[Create new bookmark_list]" }, function(input)
    if input then
      local new_list = Service.create_list(input)
      Sign.safe_refresh_signs()
      pcall(Tree.refresh, new_list.id)
    end
  end)
end

M.current_file_bookmarks_to_new_list = function()
  local filepath = Location.get_current_location().path
  local bookmarks = Service.find_bookmarks_of_file(filepath)

  local new_list = Service.create_list(vim.fn.fnamemodify(filepath, ":t"))
  for _, bookmark in pairs(bookmarks) do
    local new_node = Node.new_from_node(bookmark)
    Service.new_bookmark(new_node, new_list.id)
  end
  Sign.safe_refresh_signs()
  pcall(Tree.refresh, new_list.id)
end

-- M.attach_desc = function()
--   local bookmark = Service.find_bookmark_by_location() or Node.new_bookmark("")
--   local popup = Window.new_popup_window()
--
--   -- Set buffer options
--   vim.api.nvim_buf_set_option(popup.buf, "buftype", "acwrite")
--   vim.api.nvim_buf_set_option(popup.buf, "filetype", "markdown")
--   vim.api.nvim_buf_set_option(popup.buf, "bufhidden", "wipe")
--
--   -- Load existing description
--   vim.api.nvim_buf_set_lines(popup.buf, 0, -1, false, vim.split(bookmark.description or "", "\n"))
--
--   -- Set window options
--   vim.api.nvim_win_set_option(popup.win, "wrap", true)
--   vim.api.nvim_win_set_option(popup.win, "cursorline", true)
--   vim.api.nvim_win_set_option(popup.win, "winbar", "Press <CR> to save, q to quit")
--
--   -- Set keymaps
--   vim.keymap.set("n", "<CR>", function()
--     bookmark.description = table.concat(vim.api.nvim_buf_get_lines(popup.buf, 0, -1, false), "\n")
--     if bookmark.id then
--       Service.rename_node(bookmark.id, bookmark.name)
--     else
--       Service.new_bookmark(bookmark)
--     end
--     vim.api.nvim_win_close(popup.win, true)
--   end, { buffer = popup.buf })
--
--   vim.keymap.set("n", "q", function()
--     vim.api.nvim_win_close(popup.win, true)
--   end, { buffer = popup.buf })
-- end
--
-- M.show_desc = function()
--   local bookmark = Service.find_bookmark_by_location()
--   if not bookmark or not bookmark.description then
--     vim.notify("No description found for this bookmark", vim.log.levels.WARN)
--     return
--   end
--
--   local popup = Window.new_popup_window()
--
--   -- Set buffer options
--   vim.api.nvim_buf_set_option(popup.buf, "buftype", "nofile")
--   vim.api.nvim_buf_set_option(popup.buf, "filetype", "markdown")
--   vim.api.nvim_buf_set_option(popup.buf, "modifiable", false)
--
--   -- Load description
--   vim.api.nvim_buf_set_lines(popup.buf, 0, -1, false, vim.split(bookmark.description, "\n"))
--
--   -- Set window options
--   vim.api.nvim_win_set_option(popup.win, "wrap", true)
--   vim.api.nvim_win_set_option(popup.win, "cursorline", true)
--   vim.api.nvim_win_set_option(popup.win, "winbar", "Press q to close")
--
--   -- Set keymap to close
--   vim.keymap.set("n", "q", function()
--     vim.api.nvim_win_close(popup.win, true)
--   end, { buffer = popup.buf })
-- end

return M
