local Picker = require("bookmarks.picker")
local Service = require("bookmarks.domain.service")
local Sign = require("bookmarks.sign")

local M = {}

M.setup = require("bookmarks.config").setup

M.toggle_mark = function()
  local b = Service.find_bookmark_by_location()
  vim.ui.input({ prompt = "[Bookmarks Toggle]", default = b and b.name or "" }, function(input)
    if input then
      Service.toggle_mark(input)
      Sign.safe_refresh_signs()
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

M.bookmark_lists = function()
  Picker.pick_bookmark_list(function(bookmark_list)
    if bookmark_list then
      Service.set_active_list(bookmark_list.id)
      M.goto_bookmark()
    end
  end)
end

M.create_bookmark_list = function()
  vim.ui.input({ prompt = "[Create new bookmark_list]" }, function(input)
    if input then
      local new_list = Service.create_list(input)
      Service.set_active_list(new_list.id)
      Sign.safe_refresh_signs()
    end
  end)
end

return M
