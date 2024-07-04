local utils = require("bookmarks.utils")

---@class Bookmarks.Location
---@field path string -- as fallback if project_name can't find it's related project_path in bookmark_list
---@field project_name string? -- try to make it portable
---@field relative_path string? -- relative_path to the project
---@field line number
---@field col number

local location_scope = (function()
  local LOCATION_SCOPE = {}

  ---@return Bookmarks.Location
  function LOCATION_SCOPE.get_current_location()
    local cursor = vim.api.nvim_win_get_cursor(0)
    return {
      path = vim.fn.expand("%:p"),
      project_name = utils.find_project_name(),
      relative_path = utils.get_buf_relative_path(),
      line = cursor[1],
      col = cursor[2],
    }
  end

  return LOCATION_SCOPE
end)()

---@class Bookmarks.Bookmark
---@field id number -- pk, unique
---@field name string
---@field location Bookmarks.Location
---@field content string
---@field githash string
---@field listname? string
---@field created_at number -- pk, timestamp os.time()
---@field visited_at number -- timestamp os.time()

local bookmark_scope = (function()
  local BOOKMARK_SCOPE = {}

  ---@param name? string
  ---@return Bookmarks.Bookmark
  function BOOKMARK_SCOPE.new_bookmark(name)
    local time = os.time()
    local location = location_scope.get_current_location()

    return {
      id = time,
      name = name or "",
      location = location,
      content = vim.api.nvim_get_current_line(),
      githash = utils.get_current_version(),
      created_at = time,
      visited_at = time,
    }
  end

  ---get the fullpath of a bookmark by it's project and relative_path
  ---@param self Bookmarks.Bookmark
  ---@param projects Bookmarks.Project[]
  ---@return string
  function BOOKMARK_SCOPE.fullpath(self, projects)
    local project_path
    for _, p in ipairs(projects) do
      if p.name == self.name then
        project_path = p.path
      end
    end

    if project_path and self.location.relative_path then
      return project_path .. "/" .. self.location.relative_path
    else
      return self.location.path
    end
  end

  ---@param b1 Bookmarks.Bookmark
  ---@param b2 Bookmarks.Bookmark
  ---@param projects Bookmarks.Project[]
  ---@return boolean
  function BOOKMARK_SCOPE.is_same_location(b1, b2, projects)
    if
      BOOKMARK_SCOPE.fullpath(b1, projects) == BOOKMARK_SCOPE.fullpath(b2, projects)
      and b1.location.line == b2.location.line
    then
      return true
    end
    return false
  end

  return BOOKMARK_SCOPE
end)()

-- TODO: remove id in bookmark_list, name as identifier

---@class Bookmarks.BookmarkList
---@field name string -- pk, unique
---@field is_active boolean
---@field project_path_name_map {string: string}
---@field bookmarks Bookmarks.Bookmark[]

local bookmark_list_scope = (function()
  local BOOKMARK_LIST = {}

  ---@param self Bookmarks.BookmarkList
  ---@param bookmark Bookmarks.Bookmark
  ---@param projects Bookmarks.Project[]
  ---@return boolean
  function BOOKMARK_LIST.contains_bookmark(self, bookmark, projects)
    for _, b in ipairs(self.bookmarks) do
      ---@cast b Bookmarks.Bookmark
      if bookmark_scope.is_same_location(b, bookmark, projects) then
        return true
      end
    end

    return false
  end

  ---new a bookmark list
  ---@return Bookmarks.BookmarkList
  function BOOKMARK_LIST.new(name, id)
    return {
      id = id,
      name = name,
      bookmarks = {},
      is_active = true,
    }
  end

  ---add a bookmark into bookmark_list
  ---@param self Bookmarks.BookmarkList
  ---@param bookmark Bookmarks.Bookmark
  function BOOKMARK_LIST.add_bookmark(self, bookmark)
    table.insert(self.bookmarks, bookmark)
  end

  ---@param self Bookmarks.BookmarkList
  ---@param bookmark Bookmarks.Bookmark
  function BOOKMARK_LIST.remove_bookmark(self, bookmark, projects)
    local new_bookmarks = {}
    for _, b in ipairs(self.bookmarks) do
      if not bookmark_scope.is_same_location(b, bookmark, projects) then
        table.insert(new_bookmarks, b)
      end
    end
    self.bookmarks = new_bookmarks
  end

  ---@param self Bookmarks.BookmarkList
  ---@param location Bookmarks.Location
  ---@return Bookmarks.Bookmark?
  function BOOKMARK_LIST.find_bookmark_by_location(self, location)
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
  function BOOKMARK_LIST.toggle_bookmarks(self, bookmark, projects)
    local updated_bookmark_list = utils.deep_copy(self)

    local existing_bookmark = BOOKMARK_LIST.find_bookmark_by_location(updated_bookmark_list, bookmark.location)
    if existing_bookmark then
      if bookmark.name == "" then
        BOOKMARK_LIST.remove_bookmark(updated_bookmark_list, existing_bookmark, projects)
      else
        BOOKMARK_LIST.remove_bookmark(updated_bookmark_list, existing_bookmark, projects)
        BOOKMARK_LIST.add_bookmark(updated_bookmark_list, bookmark)
      end
    else
      table.insert(updated_bookmark_list.bookmarks, bookmark)
    end

    return updated_bookmark_list
  end

  return BOOKMARK_LIST
end)()

---@param bookmark_lists Bookmarks.BookmarkList[]
---@return string[]
local function all_list_names(bookmark_lists)
  local result = {}
  for _, bookmark_list in ipairs(bookmark_lists) do
    table.insert(result, bookmark_list.name)
  end
  return result
end

---@class Bookmarks.Project
---@field name string
---@field path string

local project_scope = (function()
  local PROJECT_SCOPE = {}

  ---@param name string
  ---@param path string?
  ---@return Bookmarks.Project
  function PROJECT_SCOPE.new(name, path)
    return {
      name = name,
      path = path or utils.find_project_path(),
    }
  end

  ---register new project if it's not exising already
  ---@param existing Bookmarks.Project[]
  ---@param name string
  ---@param path string?
  ---@return Bookmarks.Project?
  function PROJECT_SCOPE.register_new(existing, name, path)
    for _, p in ipairs(existing) do
      if p.name == name then
        return
      end
    end
    return PROJECT_SCOPE.new(name, path)
  end

  return PROJECT_SCOPE
end)()

-- TODO: turn those functions into instance methods
return {
  all_list_names = all_list_names,
  location = location_scope,
  bookmark = bookmark_scope,
  bookmark_list = bookmark_list_scope,
  project = project_scope,
}
