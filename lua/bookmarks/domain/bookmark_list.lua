local bookmark_scope = require("bookmarks.domain.bookmark")
local utils = require("bookmarks.utils")
local _type = require("bookmarks.domain.type").type
local _get_value_type = require("bookmarks.domain.type").get_value_type

---@class Bookmarks.BookmarkList
---@field id string
---@field name string
---@field is_active boolean
---@field project_path_name_map {string: string}  -- bookmark specific path_name map, used to allow overwrite the project path to share with others
---@field bookmarks Bookmarks.Node[]
---@field collapse boolean treeview runtime status, may need refactor this field later

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
    local b_type = _get_value_type(b)
    if b_type == _type.BOOKMARK then
      ---@cast b Bookmarks.Bookmark
      if b.location.path == location.path and b.location.line == location.line then
        return b
      end
    end
  end
  return nil
end

---@param self Bookmarks.BookmarkList
---@param path string
---@param projects Bookmarks.Project[]
---@return Bookmarks.Bookmark[]
function M.find_bookmarks_by_abs_path(self, path, projects)
  local r = {}
  for _, b in ipairs(M.get_all_marks(self)) do
    if bookmark_scope.fullpath(b, projects) == path then
      table.insert(r, b)
    end
  end
  return r
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
---@return Bookmarks.Bookmark?
function M.find_bookmark_by_id(self, id)
  for _, b in ipairs(self.bookmarks) do
    if b.id == id then
      ---@type Bookmarks.Bookmark
      return b
    end

    if _get_value_type(b) == _type.BOOKMARK_LIST then
      ---@cast b Bookmarks.BookmarkList
      M.find_bookmark_by_id(b, id)
    end
  end
  return nil
end

---get all bookmarks in one dimension array
---@param self Bookmarks.BookmarkList
---@return Bookmarks.Bookmark[]
function M.get_all_marks(self)
  local r = {}

  local function __get_all_marks(list, result)
    for _, b in ipairs(list.bookmarks) do
      if _get_value_type(b) == _type.BOOKMARK then
        ---@cast b Bookmarks.Bookmark
        table.insert(result, b)
      else
        __get_all_marks(b, result)
      end
    end
  end

  __get_all_marks(self, r)

  return r
end

return M
