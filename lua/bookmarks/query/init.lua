local RawQueryParser = require("bookmarks.query.raw_query_parser")
local Query = require("bookmarks.query.query")
local M = {}

---@class Bookmarks.QueryCtx
local _cache = {
  ---@type PresentView
  view = nil,
  ---@type Bookmarks.Query
  query = {},
}

--- require("bookmarks.query").display()
M.display = function()
  if _cache.view then
    _cache.view:toggle()
    return
  end

  M.init():toggle()
end

---init a new present view
M.init = function()
  local data = Query.query({})
  if type(data) ~= "table" then
    vim.notify("No data found", vim.log.levels.WARN, { title = "bookmarks.nvim" })
    return
  end
  local present = require("bookmarks.query.present_table")
  local p = present:new(data, {
    { modes = { "n", "v" }, keys = { "<localleader>f" }, action = M.add_query_condition },
    { modes = { "n", "v" }, keys = { "<localleader>d" }, action = M.clear_query_condition },
  })

  _cache = {
    view = p,
    query = {},
  }
  return p
end

-- M.add_query_condition = function()
--   -- user input condition raw string
--   ---@param condition string # where condition like "name like '%test%'" or "id = 1" or "order > 1" or "id in (1, 2, 3)"
--   -- parse condition and add
--   -- update vim.g.bookmarks_query
--   -- render bookmarks_query
--   -- update view's before_data_sections
--   -- trigger view render again
-- end

M.add_query_condition = function()
  vim.ui.input({
    prompt = "Enter query condition (e.g., name like '%test%'): ",
  }, function(condition)
    if not condition or condition == "" then
      vim.notify("Invalid condition", vim.log.levels.WARN, { title = "bookmarks.nvim" })
      return
    end

    local query_condition = RawQueryParser.parse_condition_to_query(condition)
    vim.print(query_condition)
    local ctx = _cache
    local current_query = ctx.query
    vim.print(current_query)
    if query_condition then
      current_query = vim.tbl_deep_extend("force", ctx.query, query_condition)
    end
    _cache = {
      view = ctx.view,
      query = current_query,
    }

    vim.print(current_query)
    -- Get fresh data with structured query
    local data = Query.query(current_query)

    if type(data) ~= "table" then
      vim.notify("No data found with given condition", vim.log.levels.WARN, { title = "bookmarks.nvim" })
      return
    end

    -- Update view with new data
    if _cache.view then
      local view = _cache.view
      view:set_data(data)
      view:add_before_data_section({ string.format("WHERE %s", condition) })
      view:render()
    end
  end)
end

M.clear_query_condition = function()
  local current = _cache
  _cache = {
    view = current.view,
    query = {},
  }
  current.view:reset_before_data_sections()
end

return M
