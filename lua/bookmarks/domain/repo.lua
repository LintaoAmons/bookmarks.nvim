local M = {}
local has_sqlite, sqlite = pcall(require, "sqlite")
if not has_sqlite then
  error("This plugin requires sqlite.lua (https://github.com/kkharji/sqlite.lua) " .. tostring(sqlite))
end

local tbl = require("sqlite.tbl")

-- Database schema definitions
local nodes = tbl("nodes", {
  id = true,
  type = { "text", required = true },
  name = { "text", required = true },
  description = "text",
  content = "text",
  githash = "text",
  location_path = "text",
  location_line = "integer",
  location_col = "integer",
  created_at = { "integer", required = true },
  visited_at = "integer",
  is_active = "integer",
})

local node_relationships = tbl("node_relationships", {
  id = true,
  parent_id = { type = "integer", reference = "nodes.id", on_delete = "cascade" },
  child_id = { type = "integer", reference = "nodes.id", on_delete = "cascade" },
  created_at = { "integer", required = true },
})

local active_list = tbl("active_list", {
  id = true,
  list_id = { type = "integer", reference = "nodes.id", on_delete = "cascade" },
  updated_at = { "integer", required = true },
})

---@class BookmarksDB: sqlite_db
---@field nodes sqlite_tbl
---@field node_relationships sqlite_tbl
---@field active_list sqlite_tbl
local DB = sqlite({
  uri = vim.fn.stdpath("data") .. "/bookmarks.sqlite.db",
  nodes = nodes,
  node_relationships = node_relationships,
  active_list = active_list,
})

M._DB = DB

---Initialize the database and create root node if it doesn't exist
function M.setup()
  local existing_root = DB.nodes:where({ id = 0 })
  if not existing_root then
    DB.nodes:insert({
      id = 0,
      type = "list",
      name = "root",
      description = "root",
      created_at = os.time(),
    })
  end
end

---Convert a node to a database row
---@param node Bookmarks.Node | Bookmarks.NewNode
---@return table
local function node_to_db_row(node)
  local row = {
    id = node.id,
    type = node.type,
    name = node.name,
    description = node.description,
    content = node.content,
    githash = node.githash,
    created_at = node.created_at,
    visited_at = node.visited_at,
    is_active = node.is_active and 1 or 0,
  }

  if node.location then
    row.location_path = node.location.path
    row.location_line = node.location.line
    row.location_col = node.location.col
  end

  return row
end

---Convert a database row to a node
---@param row table
---@return Bookmarks.Node
local function db_row_to_node(row)
  local node = {
    id = row.id,
    type = row.type,
    name = row.name,
    description = row.description,
    content = row.content,
    githash = row.githash,
    created_at = row.created_at,
    visited_at = row.visited_at,
    is_active = row.is_active == 1,
    children = {},
  }

  if row.location_path then
    node.location = {
      path = row.location_path,
      line = row.location_line,
      col = row.location_col,
    }
  end

  local relationships = DB.node_relationships:get({ where = { parent_id = node.id } })
  for _, rel in ipairs(relationships) do
    local child = DB.nodes:where({ id = rel.child_id })
    if child then
      table.insert(node.children, db_row_to_node(child))
    end
  end

  return node
end

---Find a node by its ID. recursively, node with children
---@param target_id number
---@return Bookmarks.Node?
function M.find_node(target_id)
  local row = DB.nodes:where({ id = target_id })
  if not row then
    return nil
  end
  return db_row_to_node(row)
end

---Insert a new node into the database
---@param node Bookmarks.NewNode
---@param parent_id number?
---@return number # The ID of the inserted node
function M.insert_node(node, parent_id)
  parent_id = parent_id or 0
  local row = node_to_db_row(node)
  local id = DB.nodes:insert(row)

  DB.node_relationships:insert({
    parent_id = parent_id,
    child_id = id,
    created_at = os.time(),
  })

  return id
end

---Update an existing node
---@param node Bookmarks.Node
---@return Bookmarks.Node
function M.update_node(node)
  local row = node_to_db_row(node)
  DB.nodes:update({ where = { id = node.id }, set = row })
  return M.find_node(node.id) or error("Node not found after update")
end

---Get all bookmark nodes
---@return Bookmarks.Node[] # Array of bookmark nodes
function M.get_all_bookmarks()
  local rows = DB.nodes:get({ where = { type = "bookmark" } })
  local results = {}
  for _, row in ipairs(rows) do
    table.insert(results, db_row_to_node(row))
  end
  return results
end

---Delete a node and all its relationships
---@param node_id number
function M.delete_node(node_id)
  -- First delete all relationships
  DB.node_relationships:remove({ where = {
    child_id = node_id,
  } })

  -- Then delete the node itself
  DB.nodes:remove({ where = { id = node_id } })
end

---Add a node to a list
---@param node_id number # The ID of the node to add
---@param parent_id number # The ID of the list to add to
function M.add_to_list(node_id, parent_id)
  DB.node_relationships:insert({
    parent_id = parent_id,
    child_id = node_id,
    created_at = os.time(),
  })
end

---Remove a node from a list (delete relationship only)
---@param node_id number
---@param list_id number
function M.remove_from_list(node_id, list_id)
  DB.node_relationships:remove({
    where = {
      child_id = node_id,
      parent_id = list_id,
    },
  })
end

---Move a node from one list to another
---@param node_id number
---@param from_list_id number
---@param to_list_id number
function M.move_node(node_id, from_list_id, to_list_id)
  -- Remove from old list
  M.remove_from_list(node_id, from_list_id)

  -- Add to new list
  M.add_to_list(node_id, to_list_id)
end

--- WARN: Don't use this function since we only allow one active list at a time now.
--- TODO: Better rename this to is expanded
---Toggle a list's active state
---@param list_id number
---@return Bookmarks.Node
function M.toggle_list_active(list_id)
  local node = M.find_node(list_id)
  if not node or node.type ~= "list" then
    error("Node not found or not a list")
  end

  local new_state = not node.is_active
  DB.nodes:update({
    where = { id = list_id },
    set = { is_active = new_state and 1 or 0 },
  })

  return M.find_node(list_id) or error("Node not found after update")
end

---Set the active list
---@param list_id number
function M.set_active_list(list_id)
  local node = M.find_node(list_id)
  if not node or node.type ~= "list" then
    error("Invalid list")
  end

  -- Clear any existing active list
  DB.active_list:remove()

  -- Set new active list
  DB.active_list:insert({
    list_id = list_id,
    updated_at = os.time(),
  })

  -- Update visited time
  node.visited_at = os.time()
  M.update_node(node)
end

-- Add function to get active list
---@return Bookmarks.Node
function M.get_active_list()
  local active = DB.active_list:get()[1]
  if not active then
    return M.find_node(0) or error("Failed to fallback to root list when no active list exists")
  end
  return M.find_node(active.list_id) or error("Failed to find active list by the id found in the active list table")
end

---find a node by location
---@param location Bookmarks.Location
---@return Bookmarks.Node?
function M.find_bookmark_by_location(location)
  local row = DB.nodes:where({
    type = "bookmark",
    location_path = location.path,
    location_line = location.line,
  })

  if not row then
    return nil
  end

  return db_row_to_node(row)
end

---Find all lists except the root list, ordered by creation date
---@return Bookmarks.Node[]
function M.find_lists()
  -- Get all lists
  local rows = DB.nodes:get({
    where = { type = "list" },
    order = {
      { column = "created_at", dir = "desc" },
    },
  })

  -- Filter out root list and convert rows to nodes
  local results = {}
  for _, row in ipairs(rows) do
    if row.id ~= 0 then
      local node = db_row_to_node(row)
      table.insert(results, node)
    end
  end

  return results
end

---Find a node by location
---@param location Bookmarks.Location
---@return Bookmarks.Node?
function M.find_node_by_location(location)
  local row = DB.nodes:where({
    type = "bookmark",
    location_path = location.path,
    location_line = location.line,
  })

  if not row then
    return nil
  end

  return db_row_to_node(row)
end

---Find bookmarks of a given file path within a list
---@param path string The file path to search for
---@param list_id? number Optional list ID. If not provided, uses the active list
---@return Bookmarks.Node[] Array of bookmark nodes in the specified list
function M.find_bookmarks_by_path(path, list_id)
  -- If list_id not provided, use active list
  if not list_id then
    local active_list = M.get_active_list()
    list_id = active_list.id
  end

  -- Get all relationships for the list
  local list_relationships = DB.node_relationships:get({
    where = {
      parent_id = list_id,
    },
  })

  -- Get all bookmarks matching the path
  local path_bookmarks = DB.nodes:get({
    where = {
      type = "bookmark",
      location_path = path,
    },
  })

  -- Create a lookup set of child_ids in the list
  local list_children = {}
  for _, rel in ipairs(list_relationships) do
    list_children[rel.child_id] = true
  end

  -- Find bookmarks that exist in both sets
  local results = {}
  for _, bookmark in ipairs(path_bookmarks) do
    if list_children[bookmark.id] then
      table.insert(results, db_row_to_node(bookmark))
    end
  end

  return results
end

return M
