---@class Bookmarks.Location
---@field path string
---@field line number
---@field col number

local M = {}

---Get the current location of the cursor
---@return Bookmarks.Location
function M.get_current_location()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local path = vim.api.nvim_buf_get_name(0)
  local col = vim.api.nvim_win_get_cursor(0)[2]
  return {
    path = path,
    line = line,
    col = col,
  }
end

---@param a Bookmarks.Location
---@param b Bookmarks.Location
---@return boolean # true if the locations are the same
M.same_line = function(a, b)
  return a.line == b.line and a.path == b.path
end

---Get just the file name from a location
---@param location Bookmarks.Location
---@return string # the file name without path
function M.get_file_name(location)
  return vim.fn.fnamemodify(location.path, ":t")
end

return M
