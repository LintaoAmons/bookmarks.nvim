---@class Bookmarks.TreeNode
---@field id string | number
---@field type number
---@field children Bookmarks.TreeNode[]
---@field name string


local M = {}

M.NODE_TYPE = {
  ROOT = 1,
  BOOKMARK_LIST = 2,
  BOOKMARK = 3,
  FOLDER = 4,
}

---@param id string | number
---@param type number
---@param name string?
---@return Bookmarks.TreeNode
function M.to_new_node(id, type, name)
  return {
    id = id,
    type = type,
    children = {},
    name = name or "",
  }
end

---@param node Bookmarks.TreeNode
---@param id string | number
---@return boolean
function M.remove_descendant_by_id(node, id)
  for i, child in ipairs(node.children) do
    if child.id == id then
      table.remove(node.children, i)
      return true
    end

    if M.remove_descendant_by_id(child, id) then
      return true
    end
  end

  return false
end

function M.add_child(node, child)
  table.insert(node.children, child)
end

function M.get_pos(father, child)
  for i, c in ipairs(father.children) do
    if c == child then
      return i
    end
  end
end

function M.add_brother(father, child, brother)
  local pos = M.get_pos(father, child)
  table.insert(father.children, pos + 1, brother)
end

return M
