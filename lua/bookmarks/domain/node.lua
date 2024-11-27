local M = {}
local Location = require("bookmarks.domain.location")
local Utils = require("bookmarks.utils")

---@class Bookmarks.Node
---@field id number
---@field name string
---@field type "bookmark"|"list"
---@field description string?
---@field children Bookmarks.Node[] # Only used if type is "list"
---@field location Bookmarks.Location? # Only used if type is "bookmark"
---@field content string? # Only used if type is "bookmark"
---@field githash string? # Only used if type is "bookmark"
---@field created_at number
---@field visited_at number?
---@field is_active boolean? # Only used if type is "list"

---@class Bookmarks.NewNode
---@field id number?
---@field name string
---@field type "bookmark"|"list"
---@field description string?
---@field children Bookmarks.NewNode[] # Only used if type is "list"
---@field location Bookmarks.Location? # Only used if type is "bookmark"
---@field content string? # Only used if type is "bookmark"
---@field githash string? # Only used if type is "bookmark"
---@field created_at number
---@field visited_at number?
---@field is_active boolean? # Only used if type is "list"

---Create a new bookmark node
---@param name string
---@return Bookmarks.NewNode
function M.new_bookmark(name)
  local time = os.time()
  return {
    type = "bookmark",
    name = name or "",
    description = "",
    location = Location.get_current_location(),
    content = vim.api.nvim_get_current_line(),
    githash = Utils.get_current_version(),
    created_at = time,
    visited_at = time,
    children = {},
  }
end

---Create a new list node
---@param name string
---@return Bookmarks.NewNode
function M.new_list(name)
  return {
    type = "list",
    description = "",
    name = name,
    children = {},
    is_active = true,
    created_at = os.time(),
  }
end

---@param node Bookmarks.Node
---@param child Bookmarks.Node
function M.add_child(node, child)
  if node.type ~= "list" then
    return
  end
  table.insert(node.children, child)
end

---@param node Bookmarks.Node
---@param target_id string|number
---@return Bookmarks.Node?
function M.find_node(node, target_id)
  if node.id == target_id then
    return node
  end
  if node.type ~= "list" then
    return nil
  end

  for _, child in ipairs(node.children) do
    local found = M.find_node(child, target_id)
    if found then
      return found
    end
  end
  return nil
end

---@param node Bookmarks.Node
---@return Bookmarks.Node[] # Returns only bookmark nodes
function M.get_all_bookmarks(node)
  local results = {}

  local function collect(n)
    if n.type == "bookmark" then
      table.insert(results, n)
    elseif n.type == "list" then
      for _, child in ipairs(n.children) do
        collect(child)
      end
    end
  end

  collect(node)
  return results
end

return M
