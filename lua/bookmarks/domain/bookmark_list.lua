local bookmark_scope = require("bookmarks.domain.bookmark")
local utils = require("bookmarks.utils")

---@class Bookmarks.BookmarkList
---@field name string
---@field is_active boolean
---@field project_path_name_map {string: string}
---@field bookmarks Bookmarks.Bookmark[]

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

return M
