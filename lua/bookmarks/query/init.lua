local M = {}

--- require("bookmarks.query").display()
M.display = function()
  local query = require("bookmarks.query.query")
  local data = query.query({})
  if type(data) ~= "table" then
    vim.notify("No data found", vim.log.levels.WARN, { title = "bookmarks.nvim" })
    return
  end
  local present = require("bookmarks.query.present_table")
  local p = present:new()
  p:setup(data)
end

return M
