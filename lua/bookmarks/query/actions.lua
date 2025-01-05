local M = {}
local Service = require("bookmarks.domain.service")
local Node = require("bookmarks.domain.node")
local State = require("bookmarks.query.state")
local RawQueryParser = require("bookmarks.query.raw_query_parser")
local Query = require("bookmarks.query.query")
local Mapper = require("bookmarks.domain.mapper")

M.add_query_condition = function()
  vim.ui.input({
    prompt = "Enter query condition, format: <column> <value> (e.g., 'id 1'): ",
  }, function(condition)
    if not condition or condition == "" then
      vim.notify("Invalid condition", vim.log.levels.WARN, { title = "bookmarks.nvim" })
      return
    end

    local query_condition = RawQueryParser.parse_condition_to_query(condition)
    local ctx = State._cache
    local current_query = ctx.query
    if query_condition then
      current_query = vim.tbl_deep_extend("force", ctx.query, query_condition)
    end

    -- Get fresh data with structured query
    local data = Query.query(current_query)

    if type(data) ~= "table" then
      vim.notify("No data found with given condition", vim.log.levels.WARN, { title = "bookmarks.nvim" })
      return
    end

    State._cache = {
      view = ctx.view,
      query = current_query,
      data = data,
    }

    -- Update view with new data
    if State._cache.view then
      local view = State._cache.view
      view:set_data(data)
      view:add_before_data_section({ string.format("WHERE %s", condition) })
      view:render()
    end
  end)
end

M.new_list_from_result = function()
  local data = State._cache.data
  if type(data) ~= "table" then
    vim.notify("No data found with given condition", vim.log.levels.WARN, { title = "bookmarks.nvim" })
    return
  end

  vim.ui.input({ prompt = "Enter list name: " }, function(name)
    if not name or name == "" then
      -- Create new list and get its ID
      local new_list = Service.create_list(name, 0)

      -- For each bookmark in the cached data
      for _, bookmark in ipairs(data) do
        local new_bookmark = Mapper.row_to_node(bookmark)
        local new_node = Node.new_from_node(new_bookmark)

        -- Insert the new bookmark under the new list
        Service.new_bookmark(new_node, new_list.id)
      end

      vim.notify(
        string.format("Created new list with %d bookmarks", #data),
        vim.log.levels.INFO,
        { title = "bookmarks.nvim" }
      )
    end
  end)
end

M.clear_query_condition = function()
  State.reset_query()
  State._cache.view:reset_before_data_sections()
  local data = Query.query(State._cache.query)
  State._cache.view:set_data(data)
  State._cache.view:render()
end

return M
