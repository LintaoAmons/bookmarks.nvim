local M = {}
---@param query Bookmarks.Query
---@return string[]
function M.render(query)
  local lines = {
    "Current Query Filters:",
    "-------------------",
    "",
  }

  ---@param name string The field name to display
  ---@param value any|nil The field value
  local function add_field(name, value)
    if value ~= nil then
      table.insert(lines, string.format("%-15s: %s", name, tostring(value)))
    end
  end

  add_field("ID", query.id)
  add_field("Type", query.type)
  add_field("Name", query.name and "%" .. query.name .. "%")
  add_field("Description", query.description and "%" .. query.description .. "%")
  add_field("Content", query.content and "%" .. query.content .. "%")
  add_field("Git Hash", query.githash)
  add_field("File Path", query.location_path)
  add_field("Line Number", query.location_line)
  add_field("Created Before", query.created_before and os.date("%Y-%m-%d %H:%M:%S", query.created_before))
  add_field("Created After", query.created_after and os.date("%Y-%m-%d %H:%M:%S", query.created_after))
  add_field("Visited Before", query.visited_before and os.date("%Y-%m-%d %H:%M:%S", query.visited_before))
  add_field("Visited After", query.visited_after and os.date("%Y-%m-%d %H:%M:%S", query.visited_after))
  add_field("Order By", query.order_by)
  add_field("Direction", query.order_dir)
  add_field("Limit", query.limit)

  if #lines == 3 then
    table.insert(lines, "No filters applied")
  end

  return lines
end

return M
