---@class Bookmarks.TreeNode
---@field id string | number
---@field type number
---@field children Bookmarks.TreeNode[]
---@field name string
---@field collapse boolean


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
    collapse = true,
  }
end

---@param father Bookmarks.TreeNode
---@param child_id string | number
function M.remove_child(father, child_id)
  for i, child in ipairs(father.children) do
    if child.id == child_id then
      table.remove(father.children, i)
      return
    end
  end
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

---@param node Bookmarks.TreeNode
---@param child Bookmarks.TreeNode
function M.add_child(node, child)
  table.insert(node.children, child)
end

---@param father Bookmarks.TreeNode
---@param child Bookmarks.TreeNode
---@return number
function M.get_pos(father, child)
  for i, c in ipairs(father.children) do
    if c == child then
      return i
    end
  end

  return -1
end

---@param father Bookmarks.TreeNode
---@param child Bookmarks.TreeNode
---@param brother Bookmarks.TreeNode
function M.add_brother(father, child, brother)
  local pos = M.get_pos(father, child)
  table.insert(father.children, pos + 1, brother)
end

---@param node Bookmarks.TreeNode
---@param id string | number
---@return Bookmarks.TreeNode | nil
function M.get_node_father(node, id)
  for _, child in ipairs(node.children) do
    if child.id == id then
      return node
    end

    local father = M.get_node_father(child, id)
    if father then
      return father
    end
  end

  return nil
end

---@param node Bookmarks.TreeNode
---@param id string | number
---@return Bookmarks.TreeNode | nil
function M.get_tree_node(node, id)
  if node.id == id then
    return node
  end

  for _, child in ipairs(node.children) do
    local _find = M.get_tree_node(child, id)
    if _find ~= nil then
      return _find
    end
  end

  return nil
end

return M
