
local utils = require("bookmarks.utils")

---@class Bookmarks.Location
---@field path string
---@field project_name string?
---@field relative_path string?
---@field line number
---@field col number

local M = {}

---@return Bookmarks.Location
function M.get_current_location()
  local cursor = vim.api.nvim_win_get_cursor(0)
  return {
    path = vim.fn.expand("%:p"),
    project_name = utils.find_project_name(),
    relative_path = utils.get_buf_relative_path(),
    line = cursor[1],
    col = cursor[2],
  }
end

return M
