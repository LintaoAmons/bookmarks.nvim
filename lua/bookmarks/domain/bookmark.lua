local utils = require("bookmarks.utils")
local location_scope = require("bookmarks.domain.location")

---@class Bookmarks.Bookmark
---@field id number
---@field name string
---@field location Bookmarks.Location
---@field content string
---@field githash string
---@field order number -- the order of the bookmark in the list
---@field listname? string -- TODO: remove this field, only used in repo when trying to find all marks, which is not reasonable
---@field created_at number
---@field visited_at number

local M = {}

---@param name? string
---@return Bookmarks.Bookmark
function M.new_bookmark(name)
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
function M.fullpath(self, projects)
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
function M.is_same_location(b1, b2, projects)
  if M.fullpath(b1, projects) == M.fullpath(b2, projects) and b1.location.line == b2.location.line then
    return true
  end
  return false
end

---@param self Bookmarks.Bookmark
---@return {has_msg: boolean, msg: string, changed: boolean}
function M.calibrate(self)
  local msg = ""
  local has_msg = false
  local file = io.open(self.location.path, "r")
  local line_no = 1
  local new_line_no = -1
  local changed = false

  if not file then
    msg = "file not found"
    goto ret
  end

  for line in file:lines() do
    if line ~= self.content then
      goto continue
    end

    if new_line_no == -1 then
      new_line_no = line_no
      if new_line_no == self.location.line then
        goto ret
      end
    else
      msg = "content is not unique"
      new_line_no = -1
      goto ret
    end

    ::continue::
    line_no = line_no + 1
  end

  if new_line_no == -1 then
    msg = "content not found"
    goto ret
  end

  msg = string.format("line number changed from %d to %d", self.location.line, new_line_no)
  self.location.line = new_line_no
  changed = true

  ::ret::
  if file then
    file:close()
  end

  if msg ~= "" then
    has_msg = true
  end

  msg = string.format("[%s]%s:%s ----> %s",
    self.name,
    self.location.relative_path,
    self.content,
    msg
  )

  return {
    has_msg = has_msg,
    msg = msg,
    changed = changed,
  }
end

return M
