local Node = require("bookmarks.domain.node")

local M = {}
local has_sqlite, sqlite = pcall(require, "sqlite")
if not has_sqlite then
  error("This plugin requires sqlite.lua (https://github.com/kkharji/sqlite.lua) " .. tostring(sqlite))
end

local tbl = require("sqlite.tbl")

-- Database schema definitions
local nodes_tbl = tbl("nodes", {
  id = true,
  type = { "text", required = true },
  name = { "text", required = true },
  description = "text",
  content = "text",
  githash = "text",
  location_path = "text",
  location_line = "integer",
  location_col = "integer",
  is_expanded = "integer",
  node_order = "integer",
  created_at = { "integer", required = true },
  visited_at = "integer",
})

local node_relationships_tbl = tbl("node_relationships", {
  id = true,
  parent_id = { type = "integer", reference = "nodes.id", on_delete = "cascade" },
  child_id = { type = "integer", reference = "nodes.id", on_delete = "cascade" },
  created_at = { "integer", required = true },
})

local active_list_tbl = tbl("active_list", {
  id = true,
  list_id = { type = "integer", reference = "nodes.id", on_delete = "cascade" },
  updated_at = { "integer", required = true },
})

---@class BookmarksDB: sqlite_db
---@field uri string
---@field nodes sqlite_tbl
---@field node_relationships sqlite_tbl
---@field active_list sqlite_tbl
local DB
M._DB = DB

---Initialize the database and create root node if it doesn't exist
---@param db_dir string Directory to store the database
function M.setup(db_dir)
  DB = sqlite({
    uri = db_dir,
    nodes = nodes_tbl,
    node_relationships = node_relationships_tbl,
    active_list = active_list_tbl,
  })
  M._DB = DB

  local existing_root = DB.nodes:where({ id = 0 })
  if not existing_root then
    DB.nodes:insert({
      id = 0,
      type = "list",
      name = "root",
      description = "root",
      is_expanded = true,
      created_at = os.time(),
      node_order = 0,
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
    is_expanded = node.is_expanded and 1 or 0,
    node_order = node.order,
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

  -- Find the parent node's children count for ordering
  local children = DB.node_relationships:get({
    where = { parent_id = parent_id },
  })

  -- Set the new node's order to be after all existing children
  local row = node_to_db_row(node)
  row.node_order = #children

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
  DB.node_relationships:remove({
    where = {
      child_id = node_id,
    }
  })
  DB.node_relationships:remove({
    where = {
      parent_id = node_id,
    }
  })

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

---Toggle a list's active state
---@param list_id number
---@return Bookmarks.Node
function M.toggle_list_expanded(list_id)
  local node = M.find_node(list_id)
  if not node or node.type ~= "list" then
    error("Node not found or not a list")
  end

  local new_state = not node.is_expanded
  DB.nodes:update({
    where = { id = list_id },
    set = { is_expanded = new_state and 1 or 0 },
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

--
---@return Bookmarks.Node
function M.ensure_and_get_active_list()
  local active = DB.active_list:get()[1]
  local node

  if active then
    node = M.find_node(active.list_id)
  end

  -- Fallback to root if no active list or active list not found
  if not node then
    node = M.find_node(0)
    if not node then
      error("Failed to fallback to root list")
    end

    -- Clear any existing active list
    DB.active_list:remove()

    -- Set new active list
    DB.active_list:insert({
      list_id = node.id,
      updated_at = os.time(),
    })
  end

  return node
end

---find a node by location
---@param location Bookmarks.Location
---@param opts? { all_bookmarks: boolean }
---@return Bookmarks.Node?
function M.find_bookmark_by_location(location, opts)
  opts = opts or {}
  local row
  if opts.all_bookmarks then
    row = DB.nodes:where({
      type = "bookmark",
      location_path = location.path,
      location_line = location.line,
    })
  else
    -- find in active list
    local active_list = M.ensure_and_get_active_list()
    return Node.find_mark_by_location(active_list, location)
  end

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
    local active_list = M.ensure_and_get_active_list()
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

---Get the parent ID of a node
---@param node_id number The ID of the node to find the parent for
---@return number parent_id Returns the parent ID or nil if not found
function M.get_parent_id(node_id)
  if node_id == 0 then
    return 0
  end

  local relationship = DB.node_relationships:where({
    child_id = node_id,
  })

  if not relationship then
    error("Orphan Node, check your db for node id: " .. node_id)
  end

  return relationship.parent_id
end

function M.clean_dirty_nodes()
  local dirty_nodes = DB.nodes:get({
    where = {
      type = "bookmark",
      location_path = nil,
    },
  })

  for _, node in ipairs(dirty_nodes) do
    DB.nodes:remove({ where = { id = node.id } })
  end
end

---Insert a node at a specific position in a list
---@param node Bookmarks.NewNode The node to insert
---@param parent_id number The parent list ID
---@param position number The position to insert at
---@return number # The ID of the inserted node
function M.insert_node_at_position(node, parent_id, position)
  -- Get all children of the parent
  local children = DB.node_relationships:get({
    where = { parent_id = parent_id },
  })

  -- Validate position
  if position < 0 then
    position = 0
  elseif position > #children then
    position = #children
  end

  -- Shift orders of existing nodes
  for _, rel in ipairs(children) do
    local child = DB.nodes:where({ id = rel.child_id })
    if child and child.node_order >= position then
      DB.nodes:update({
        where = { id = child.id },
        set = { node_order = child.node_order + 1 },
      })
    end
  end

  -- Insert the new node with the specified order
  local row = node_to_db_row(node)
  row.node_order = position

  local id = DB.nodes:insert(row)

  -- Create relationship
  DB.node_relationships:insert({
    parent_id = parent_id,
    child_id = id,
    created_at = os.time(),
  })

  return id
end

---Find and fix orphaned nodes by attaching them to the root node
function M.rebind_orphan_node()
  -- Get all nodes
  local nodes = DB.nodes:get()

  -- Filter out root node in memory
  local non_root_nodes = {}
  for _, node in ipairs(nodes) do
    if node.id ~= 0 then
      table.insert(non_root_nodes, node)
    end
  end

  -- Get all relationships
  local relationships = DB.node_relationships:get()
  local has_parent = {}

  -- Build lookup table of nodes with parents
  for _, rel in ipairs(relationships) do
    has_parent[rel.child_id] = true
  end

  -- Find orphaned nodes and attach them to root
  for _, node in ipairs(non_root_nodes) do
    if not has_parent[node.id] then
      -- Get count of root's children for ordering
      local root_children = DB.node_relationships:get({
        where = { parent_id = 0 },
      })

      -- Create relationship with root
      DB.node_relationships:insert({
        parent_id = 0,
        child_id = node.id,
        created_at = os.time(),
      })

      -- Update node's order to be at the end
      DB.nodes:update({
        where = { id = node.id },
        set = { node_order = #root_children },
      })
    end
  end
end

return M
