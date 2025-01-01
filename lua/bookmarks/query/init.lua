local RawQueryParser = require("bookmarks.query.raw_query_parser")
local Query = require("bookmarks.query.query")
local M = {}

--- require("bookmarks.query").display()
M.display = function()
  if vim.g.bookmarks_query_ctx.view then
    vim.g.bookmarks_query_ctx.view.view:toggle()
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
    { modes = { "n", "v" }, keys = { "q" }, action = M.add_query_condition },
    { modes = { "n", "v" }, keys = { "<localleader>f" }, action = M.add_query_condition },
    { modes = { "n", "v" }, keys = { "<localleader>d" }, action = M.clear_query_condition },
  })
  vim.print(p)
  vim.g.bookmarks_query_ctx = {
    view = p,
    query = {},
  }
  vim.print(vim.g.bookmarks_query_ctx)
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
    local ctx = vim.g.bookmarks_query_ctx
    local current_query = ctx.query
    if query_condition then
      current_query = vim.tbl_deep_extend("force", ctx.query, query_condition)
    end
    vim.g.bookmarks_query_ctx = {
      view = ctx.view,
      query = current_query,
    }

    -- Get fresh data with structured query
    local data = Query.query(current_query)

    if type(data) ~= "table" then
      vim.notify("No data found with given condition", vim.log.levels.WARN, { title = "bookmarks.nvim" })
      return
    end

    -- Update view with new data
    if vim.g.bookmarks_query_ctx.view then
      local view = vim.g.bookmarks_query_ctx.view.view
      view:set_data(data)
      view:add_before_data_section({ string.format("WHERE %s", condition) })
      view:render()
    end
  end)
end

M.clear_query_condition = function()
  local current = vim.g.bookmarks_query_ctx
  vim.g.bookmarks_query_ctx.query = {
    view = current.view,
    query = {},
  }
  current.view:reset_before_data_sections()
end

return M
