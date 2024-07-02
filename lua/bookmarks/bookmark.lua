local utils = require("bookmarks.utils")

---@class Bookmarks.Location
---@field path string -- as fallback if project_name can't find it's related project_path in bookmark_list
---@field project_name string? -- try to make it portable
---@field relative_path string? -- relative_path to the project
---@field line number
---@field col number

---@class Bookmarks.Bookmark
---@field id number -- pk, unique
---@field name string
---@field location Bookmarks.Location
---@field content string
---@field githash string
---@field listname? string
---@field created_at number -- pk, timestamp os.time()
---@field visited_at number -- timestamp os.time()

-- TODO: remove id in bookmark_list, name as identifier

---@class Bookmarks.BookmarkList
---@field name string -- pk, unique
---@field is_active boolean
---@field project_path_name_map {string: string}
---@field bookmarks Bookmarks.Bookmark[]

---@param b1 Bookmarks.Bookmark
---@param b2 Bookmarks.Bookmark
---@return boolean
local function is_same_location(b1, b2)
  if b1.location.path == b2.location.path and b1.location.line == b2.location.line then
    return true
  end
  return false
end

---@param self Bookmarks.BookmarkList
---@param bookmark Bookmarks.Bookmark
---@return boolean
local function contains_bookmark(self, bookmark)
  for _, b in ipairs(self.bookmarks) do
    ---@cast b Bookmarks.Bookmark
    if is_same_location(b, bookmark) then
      return true
    end
  end

  return false
end

---@param self Bookmarks.BookmarkList
---@param bookmark Bookmarks.Bookmark
---@return Bookmarks.BookmarkList
local function remove_bookmark(self, bookmark)
  local new_bookmarks = {}
  for _, b in ipairs(self.bookmarks) do
    if not is_same_location(b, bookmark) then
      table.insert(new_bookmarks, b)
    end
  end
  self.bookmarks = new_bookmarks
end

local function add_bookmark(self, bookmark)
  table.insert(self.bookmarks, bookmark)
end

---@param self Bookmarks.BookmarkList
---@param location Bookmarks.Location
---@return Bookmarks.Bookmark?
local function find_bookmark_by_location(self, location)
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
---@return Bookmarks.BookmarkList
local function toggle_bookmarks(self, bookmark)
  local updated_bookmark_list = utils.deep_copy(self)

  local existing_bookmark = find_bookmark_by_location(updated_bookmark_list, bookmark.location)
  if existing_bookmark then
    if bookmark.name == "" then
      remove_bookmark(updated_bookmark_list, existing_bookmark)
    else
      remove_bookmark(updated_bookmark_list, existing_bookmark)
      add_bookmark(updated_bookmark_list, bookmark)
    end
  else
    table.insert(updated_bookmark_list.bookmarks, bookmark)
  end

  return updated_bookmark_list
end


---@param bookmark_lists Bookmarks.BookmarkList[]
---@return string[]
local function all_list_names(bookmark_lists)
  local result = {}
  for _, bookmark_list in ipairs(bookmark_lists) do
    table.insert(result, bookmark_list.name)
  end
  return result
end

---@return Bookmarks.Location
local function get_current_location()
  local cursor = vim.api.nvim_win_get_cursor(0)
  return {
    path = vim.fn.expand("%:p"),
    project_name = utils.find_project_name(),
    relative_path = utils.get_buf_relative_path(),
    line = cursor[1],
    col = cursor[2],
  }
end

---@param name? string
---@return Bookmarks.Bookmark
local function new_bookmark(name)
  local time = os.time()

  return {
    id = time,
    name = name or "",
    location = get_current_location(),
    content = vim.api.nvim_get_current_line(),
    githash = utils.get_current_version(),
    created_at = time,
    visited_at = time,
  }
end

-- TODO: turn those functions into instance methods
return {
  new_bookmark = new_bookmark,
  is_same_location = is_same_location,
  toggle_bookmarks = toggle_bookmarks,
  all_list_names = all_list_names,
  location = {
    get_current_location = get_current_location,
  },
  bookmark_list = {
    find_bookmark_by_location = find_bookmark_by_location,
  },
}
