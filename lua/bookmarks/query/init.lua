local State = require("bookmarks.query.state")
local Query = require("bookmarks.query.query")
local Actions = require("bookmarks.query.actions")
local M = {}

M.display = function()
  if State._cache.view then
    State._cache.view:toggle()
    return
  end

  M.init():toggle()
end

--- require("bookmarks.query").display()
---init a new present view
M.init = function()
  local data = Query.query({})
  if type(data) ~= "table" then
    vim.notify("No data found", vim.log.levels.WARN, { title = "bookmarks.nvim" })
    return
  end
  local present = require("bookmarks.query.present_table")
  local p = present:new(data, {
    { modes = { "n", "v" }, keys = { "<localleader>f" }, action = Actions.add_query_condition },
    { modes = { "n", "v" }, keys = { "<localleader>d" }, action = Actions.clear_query_condition },
    { modes = { "n", "v" }, keys = { "<localleader>a" }, action = Actions.new_list_from_result },
  })

  State._cache = {
    view = p,
    query = {},
    data = data,
  }
  return p
end

return M
