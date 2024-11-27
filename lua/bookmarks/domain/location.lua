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

return M
