local M = {}

---convert a database row to a bookmark node
---@param row table
---@return Bookmarks.Node
M.row_to_node = function(row)
  local node = {
    id = row.id,
    type = row.type,
    name = row.name,
    description = row.description,
    content = row.content,
    githash = row.githash,
    created_at = row.created_at,
    visited_at = row.visited_at,
    is_expanded = row.is_expanded == 1,
    order = row.node_order,
    children = {},
  }

  if row.location_path then
    node.location = {
      path = row.location_path,
      line = row.location_line,
      col = row.location_col,
    }
  end

  return node
end

return M
