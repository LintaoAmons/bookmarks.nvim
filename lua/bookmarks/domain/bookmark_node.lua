local _type = require("bookmarks.domain.type").type
local _get_value_type = require("bookmarks.domain.type").get_value_type
local utils = require("bookmarks.utils")
local bookmark_list = require("bookmarks.domain.bookmark_list")

---@alias Bookmarks.Node (Bookmarks.Bookmark | Bookmarks.BookmarkList)

local M = {}

---@param root Bookmarks.Node
---@param target_id string | number
---@return Bookmarks.BookmarkList?
function M.get_father(root, target_id)
  for _, child in ipairs(root.bookmarks) do
    if child.id == target_id then
      ---@type Bookmarks.BookmarkList
      return root
    end

    local cur_type = _get_value_type(child)
    if cur_type ~= _type.BOOKMARK then
      local ret = M.get_father(child, target_id)
      if ret ~= nil then
        return ret
      end
    end
  end
end

---@param father Bookmarks.BookmarkList
---@param brother Bookmarks.Node
---@param new_node Bookmarks.Node
function M.add_brother(father, brother, new_node)
  for i, child in ipairs(father.bookmarks) do
    if child.id == brother.id then
      table.insert(father.bookmarks, i + 1, new_node)
      return
    end
  end
end

---@param self Bookmarks.BookmarkList
---@param id string | number
---@return Bookmarks.Node?
function M.remove_node(self, id)
  for i, child in ipairs(self.bookmarks) do
    if child.id == id then
      return table.remove(self.bookmarks, i)
    end

    local cur_type = _get_value_type(child)
    if cur_type == _type.BOOKMARK_LIST then
      ---@cast child Bookmarks.BookmarkList
      local ret = M.remove_node(child, id)
      if ret ~= nil then
        return ret
      end
    end
  end
end

---@param self Bookmarks.BookmarkList
---@param id string | number
---@return Bookmarks.Node?
function M.copy_node(self, id)
  local node = M.get_node(self, id)
  if node == nil then
    return nil
  end

  return utils.deep_copy(node)
end

---@param self Bookmarks.BookmarkList
---@param id string | number
---@param name string
function M.create_folder(self, id, name)
  local cur_node = M.get_node(self, id)
  if cur_node == nil then
    utils.log("can't find current node")
    return
  end

  local folder_id = utils.generate_datetime_id()
  local folder = bookmark_list.new(name, folder_id)
  folder.is_active = false
  local cur_type = _get_value_type(cur_node)
  if cur_type == _type.BOOKMARK_LIST then
    table.insert(cur_node.bookmarks, folder)
    return
  end

  local father = M.get_father(self, id)
  if father == nil then
    return
  end

  -- TODO: add top level list
  M.add_brother(father, cur_node, folder)
end

---@param self Bookmarks.BookmarkList
---@param paste_id string | number
---@param node Bookmarks.Node
function M.paste(self, paste_id, node)
  local cur_node = M.get_node(self, paste_id)
  if cur_node == nil then
    return
  end

  local cur_type = _get_value_type(cur_node)
  if cur_type == _type.BOOKMARK_LIST then
    table.insert(cur_node.bookmarks, node)
    return
  end

  local cur_father = M.get_father(self, paste_id)
  if cur_father == nil then
    return
  end

  M.add_brother(cur_father, cur_node, node)
end

---@param root Bookmarks.Node
---@param target_id string | number
---@return Bookmarks.Node?
function M.get_node(root, target_id)
  if root.id == target_id then
    return root
  end

  if root.bookmarks == nil then
    return nil
  end

  for _, b in ipairs(root.bookmarks) do
    local ret = M.get_node(b, target_id)
    if ret ~= nil then
      return ret
    end
  end

  return nil
end

---@param root Bookmarks.BookmarkList
---@param target_id string | number
---@return Bookmarks.Bookmark?
function M.collapse_node(root, target_id)
  local cur_node = M.get_node(root, target_id)
  if cur_node == nil then
    return nil
  end

  local cur_type = _get_value_type(cur_node)
  if cur_type == _type.BOOKMARK then
    ---@type Bookmarks.Bookmark
    return cur_node
  end

  ---@cast cur_node Bookmarks.BookmarkList
  if cur_node.collapse then
    cur_node.collapse = false
  else
    cur_node.collapse = true
  end
end

---@param father Bookmarks.BookmarkList
---@param son string | number
---@return boolean
function M.is_descendant(father, son)
  for _, child in ipairs(father.bookmarks) do
    if child.id == son then
      return true
    end

    local cur_type = _get_value_type(child)
    if cur_type == _type.BOOKMARK_LIST then
      ---@cast child Bookmarks.BookmarkList
      local ret = M.is_descendant(child, son)
      if ret then
        return true
      end
    end
  end

  return false
end

---@param root Bookmarks.Node
---@param father string | number -- FIXME: why it could be a number?
---@param son string | number
---@return boolean
function M.is_descendant_by_id(root, father, son)
  local father_node = M.get_node(root, father)
  if father_node == nil then
    return false
  end

  local father_type = _get_value_type(father_node)
  if father_type == _type.BOOKMARK then
    return false
  end

  ---@cast father_node Bookmarks.BookmarkList
  return M.is_descendant(father_node, son)
end

return M
