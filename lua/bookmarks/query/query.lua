local DB = require("sqlite.db")
local Repo = require("bookmarks.domain.repo")

local M = {}

--- execute a raw string query
--- e.g.
--- require("bookmarks.query.api").query("select * from nodes")
---@param query string
---@return table|boolean
M.query_raw = function(query)
  local db = DB:open(Repo._DB.uri)
  return db:eval(query)
end

---@class Bookmarks.Query
---@field id number?
---@field type "bookmark"|"list"?
---@field name string? # Partial match
---@field description string? # Partial match
---@field content string? # Partial match
---@field githash string?
---@field location_path string? # Exact match
---@field location_line number?
---@field created_before number? # Unix timestamp
---@field created_after number? # Unix timestamp
---@field visited_before number? # Unix timestamp
---@field visited_after number? # Unix timestamp
---@field order_by string? # Column name to order by
---@field order_dir "asc"|"desc"? # Order direction
---@field limit number? # Max number of results

---Query bookmarks using filters
---@param filter Bookmarks.Query
---@return table|boolean
M.query = function(filter)
  local db = DB:open(Repo._DB.uri)
  local conditions = {}
  local params = {}

  -- Build WHERE conditions
  if filter.id then
    table.insert(conditions, "id = :id")
    params.id = filter.id
  end
  if filter.type then
    table.insert(conditions, "type = :type")
    params.type = filter.type
  end
  if filter.name then
    table.insert(conditions, "name LIKE :name")
    params.name = "%" .. filter.name .. "%"
  end
  if filter.description then
    table.insert(conditions, "description LIKE :description")
    params.description = "%" .. filter.description .. "%"
  end
  if filter.content then
    table.insert(conditions, "content LIKE :content")
    params.content = "%" .. filter.content .. "%"
  end
  if filter.githash then
    table.insert(conditions, "githash = :githash")
    params.githash = filter.githash
  end
  if filter.location_path then
    table.insert(conditions, "location_path LIKE :location_path")
    params.location_path = filter.location_path
  end
  if filter.location_line then
    table.insert(conditions, "location_line LIKE :location_line")
    params.location_line = filter.location_line
  end
  if filter.created_before then
    table.insert(conditions, "created_at <= :created_before")
    params.created_before = filter.created_before
  end
  if filter.created_after then
    table.insert(conditions, "created_at >= :created_after")
    params.created_after = filter.created_after
  end
  if filter.visited_before then
    table.insert(conditions, "visited_at <= :visited_before")
    params.visited_before = filter.visited_before
  end
  if filter.visited_after then
    table.insert(conditions, "visited_at >= :visited_after")
    params.visited_after = filter.visited_after
  end

  -- Construct query
  local query = "SELECT * FROM nodes"
  if #conditions > 0 then
    query = query .. " WHERE " .. table.concat(conditions, " AND ")
  end

  -- Add ordering
  if filter.order_by then
    query = query .. string.format(" ORDER BY %s %s", filter.order_by, filter.order_dir or "asc")
  end

  -- Add limit
  if filter.limit then
    query = query .. " LIMIT " .. filter.limit
  end

  -- vim.print(query, params)
  -- Execute query and convert results
  local results = db:eval(query, params)
  -- vim.print(results)
  return results
end

return M
