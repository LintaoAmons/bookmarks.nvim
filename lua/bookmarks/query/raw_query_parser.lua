local VALID_QUERY_FIELDS = {
  id = true,
  type = true,
  name = true,
  description = true,
  content = true,
  githash = true,
  location_path = true,
  location_line = true,
  created_before = true,
  created_after = true,
  visited_before = true,
  visited_after = true,
  order_by = true,
  order_dir = true,
  limit = true,
}

---Convert a condition string into a query table
---@param condition string The condition in format "column_name value"
---@return {[string]: string}|nil query The parsed query table or nil if invalid
local function parse_condition_to_query(condition)
  if not condition or type(condition) ~= "string" then
    vim.notify("Invalid condition: must be a non-empty string", vim.log.levels.WARN, { title = "bookmarks.nvim" })
    return nil
  end

  -- Parse condition into structured query
  local column_name, value = condition:match("(%w+)%s*(.*)")
  if not column_name then
    vim.notify("Invalid condition format", vim.log.levels.WARN, { title = "bookmarks.nvim" })
    return nil
  end

  -- Check if column_name is valid
  if not VALID_QUERY_FIELDS[column_name] then
    vim.notify(
      string.format("Invalid field '%s'. Must be one of the valid Bookmarks.Query fields", column_name),
      vim.log.levels.WARN,
      { title = "bookmarks.nvim" }
    )
    return nil
  end

  -- Build query table
  return { [column_name] = value }
end

return {
  parse_condition_to_query = parse_condition_to_query,
}
