local bookmark_scope = require("bookmarks.domain.bookmark")
local utils = require("bookmarks.utils")
local _type = require("bookmarks.domain.type")

---@class Bookmarks.BookmarkList
---@field name string
---@field is_active boolean
---@field project_path_name_map {string: string}
---@field bookmarks (Bookmarks.Bookmark | Bookmarks.BookmarkList)[]

local M = {}

---new a bookmark list
---@return Bookmarks.BookmarkList
function M.new(name, id)
  return {
    id = id,
    name = name,
    bookmarks = {},
    is_active = true,
  }
end

---@param self Bookmarks.BookmarkList
---@param bookmark Bookmarks.Bookmark
function M.add_bookmark(self, bookmark)
  table.insert(self.bookmarks, bookmark)
end

---@param self Bookmarks.BookmarkList
---@param location Bookmarks.Location
---@return Bookmarks.Bookmark?
function M.find_bookmark_by_location(self, location)
  -- TODO: self location path
  for _, b in ipairs(self.bookmarks) do
    if b.location.path == location.path and b.location.line == location.line then
      return b
    end
  end
  return nil
end

---@param self Bookmarks.BookmarkList
---@param bookmark Bookmarks.Bookmark
---@param projects Bookmarks.Project[]
---@return Bookmarks.BookmarkList
function M.toggle_bookmarks(self, bookmark, projects)
  local updated_bookmark_list = utils.deep_copy(self)

  local existing_bookmark = M.find_bookmark_by_location(updated_bookmark_list, bookmark.location)
  if existing_bookmark then
    if bookmark.name == "" then
      M.remove_bookmark(updated_bookmark_list, existing_bookmark, projects)
    else
      M.remove_bookmark(updated_bookmark_list, existing_bookmark, projects)
      M.add_bookmark(updated_bookmark_list, bookmark)
    end
  else
    table.insert(updated_bookmark_list.bookmarks, bookmark)
  end

  return updated_bookmark_list
end

---@param self Bookmarks.BookmarkList
---@param bookmark Bookmarks.Bookmark
function M.remove_bookmark(self, bookmark, projects)
  local new_bookmarks = {}
  for _, b in ipairs(self.bookmarks) do
    if not bookmark_scope.is_same_location(b, bookmark, projects) then
      table.insert(new_bookmarks, b)
    end
  end
  self.bookmarks = new_bookmarks
end

---@param self Bookmarks.BookmarkList
---@param bookmark Bookmarks.Bookmark
---@param projects Bookmarks.Project[]
---@return boolean
function M.contains_bookmark(self, bookmark, projects)
  for _, b in ipairs(self.bookmarks) do
    ---@cast b Bookmarks.Bookmark
    if bookmark_scope.is_same_location(b, bookmark, projects) then
      return true
    end
  end

  return false
end


---@param self Bookmarks.BookmarkList
---@param id string | number
---@return Bookmarks.BookmarkList?
function M.get_father(self, id)
  for _, child in ipairs(self.bookmarks) do
    if child.id == id then
      return self
    end

    local cur_type = M.get_value_type(child)
    if cur_type == _type.BOOKMARK then
      goto continue
    end

    local ret = M.get_father(child, id)
    if ret ~= nil then
      return ret
    end

    ::continue::
  end
end

---@param father Bookmarks.BookmarkList
---@param brother Bookmarks.Bookmark | Bookmarks.BookmarkList
---@param new_node Bookmarks.Bookmark | Bookmarks.BookmarkList
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
---@return (Bookmarks.BookmarkList | Bookmarks.Bookmark)?
function M.remove_node(self, id)
  for i, child in ipairs(self.bookmarks) do
    if child.id == id then
      return table.remove(self.bookmarks, i)
    end

    local cur_type = M.get_value_type(child)
    if cur_type == _type.BOOKMARK then
      goto continue
    end

    local ret = M.remove_node(child, id)
    if ret ~= nil then
      return ret
    end

    ::continue::
  end
end

---@param self Bookmarks.BookmarkList
---@param id string | number
---@return (Bookmarks.BookmarkList | Bookmarks.Bookmark)?
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
  local folder = M.new(name, folder_id)
  local cur_type = M.get_value_type(cur_node)
  if cur_type == _type.BOOKMARK_LIST then
    table.insert(cur_node.bookmarks, folder)
    return
  end

  local father = M.get_father(self, id)
  if father == nil then
    return
  end

  M.add_brother(father, cur_node, folder)
end

---@param self Bookmarks.BookmarkList
---@param paste_id string | number
---@param node Bookmarks.Bookmark | Bookmarks.BookmarkList
function M.paste(self, paste_id, node)
  local cur_node = M.get_node(self, paste_id)
  if cur_node == nil then
    return
  end

  local cur_type = M.get_value_type(cur_node)
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

---@param self Bookmarks.BookmarkList | Bookmarks.Bookmark
---@param id string | number
---@return (Bookmarks.Bookmark | Bookmarks.BookmarkList) ?
function M.get_node(self, id) 
  if self.id == id then
    return self
  end

  if self.bookmarks == nil then
    return nil
  end

  for _, b in ipairs(self.bookmarks) do
    local ret = M.get_node(b, id)
    if ret ~= nil then
      return ret
    end
  end

  return nil
end

---@param self Bookmarks.BookmarkList
---@param id string | number
---@return Bookmarks.Bookmark?
function M.collapse_node(self, id)
  local cur_node = M.get_node(self, id)
  if cur_node == nil then
    return nil
  end

  local cur_type = M.get_value_type(cur_node)
  if cur_type == _type.BOOKMARK then
    return cur_node
  end
  if cur_node.collapse then
    cur_node.collapse = false
  else
    cur_node.collapse = true
  end
end


---@param self Bookmarks.BookmarkList
---@param id string | number
---@return Bookmarks.Bookmark?
function M.find_bookmark_by_id(self, id)
  for _, b in ipairs(self.bookmarks) do
    if b.id == id then
      return b
    end
  end
  return nil
end

---@param val Bookmarks.BookmarkList | Bookmarks.Bookmark
---@return number
function M.get_value_type(val)
  if val.bookmarks ~= nil then
    return _type.BOOKMARK_LIST
  else
    return _type.BOOKMARK
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

    local cur_type = M.get_value_type(child)
    if cur_type == _type.BOOKMARK then
      goto continue
    end

    local ret = M.is_descendant(child, son)
    if ret then
      return true
    end

    ::continue::
  end

  return false
end

---@param self Bookmarks.BookmarkList
---@param father string | number
---@param son string | number
---@return boolean
function M.is_descendant_by_id(self, father, son)
  local father_node = M.get_node(self, father)
  if father_node == nil then
    return false
  end

  local father_type = M.get_value_type(father_node)
  if father_type == _type.BOOKMARK then
    return false
  end

  return M.is_descendant(father_node, son)
end

return M
