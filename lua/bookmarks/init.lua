local Picker = require("bookmarks.picker")
local Service = require("bookmarks.domain.service")
local Repo = require("bookmarks.domain.repo")
local Node = require("bookmarks.domain.node")
local Sign = require("bookmarks.sign")
local Location = require("bookmarks.domain.location")
local Commands = require("bookmarks.commands")
local Tree = require("bookmarks.tree.operate")

local M = {}

M.setup = require("bookmarks.config").setup

M.toggle_mark = function()
  local b = Service.find_bookmark_by_location()
  vim.ui.input({ prompt = "[Bookmarks Toggle]", default = b and b.name or "" }, function(input)
    if input then
      Service.toggle_mark(input)
      Sign.safe_refresh_signs()
      pcall(Tree.refresh)
    end
  end)
end

M.goto_bookmark = function()
  Picker.pick_bookmark(function(bookmark)
    if bookmark then
      Service.goto_bookmark(bookmark.id)
      Sign.safe_refresh_signs()
    end
  end)
end

M.grep_bookmarks = function()
  require("bookmarks.picker").grep_bookmark()
end

M.bookmark_lists = function()
  Picker.pick_bookmark_list(function(bookmark_list)
    if bookmark_list then
      Service.set_active_list(bookmark_list.id)
      M.goto_bookmark()
    end
  end)
end

M.create_bookmark_list = Commands.new_list

M.info = function()
  require("bookmarks.info").open()
end

M.bookmark_info = function()
  require("bookmarks.info").show_bookmark_info()
end

M.commands = function()
  Picker.pick_commands()
end

M.attach_desc = function()
  local bookmark = Service.find_bookmark_by_location() or Node.new_bookmark("")
  local popup = require("bookmarks.utils.window").description_window()

  -- Set buffer options
  vim.api.nvim_buf_set_option(popup.buf, "buftype", "acwrite")
  vim.api.nvim_buf_set_option(popup.buf, "filetype", "markdown")
  vim.api.nvim_buf_set_option(popup.buf, "bufhidden", "wipe")

  -- Get existing bookmark description if any
  vim.api.nvim_buf_set_lines(popup.buf, 0, -1, false, vim.split(bookmark.description, "\n"))

  -- Set window options
  vim.api.nvim_win_set_option(popup.win, "wrap", true)
  vim.api.nvim_win_set_option(popup.win, "cursorline", true)
  vim.api.nvim_win_set_option(popup.win, "winbar", "Press <CR> to save, q to quit")

  -- Set keymaps
  vim.keymap.set("n", "<CR>", function()
    bookmark.description = table.concat(vim.api.nvim_buf_get_lines(popup.buf, 0, -1, false), "\n")
    if bookmark.id then
      ---@cast bookmark Bookmarks.Node
      Repo.update_node(bookmark)
    else
      ---@cast bookmark Bookmarks.NewNode
      Service.new_bookmark(bookmark)
    end
    vim.api.nvim_win_close(popup.win, true)
  end, { buffer = popup.buf })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(popup.win, true)
  end, { buffer = popup.buf })

  -- Set buffer title
  vim.api.nvim_win_set_cursor(popup.win, { 1, 0 })
end

M.toggle_treeview = function()
  require("bookmarks.tree").toggle()
end

M.rebind_orphan_node = function()
  Repo.rebind_orphan_node()
end

return M
