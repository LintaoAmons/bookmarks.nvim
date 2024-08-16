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

---@param self Bookmarks.Bookmark
---@param projects Bookmarks.Project[]
---@return {has_msg: boolean, msg: string, changed: boolean}
function M.calibrate(self, projects)
  if not self.content or self.content == "" then
    return { has_msg = false, msg = "", changed = false }
  end

  local prefix = string.format("[%s]%s:%s ----> ", self.name, self.location.relative_path, self.content)
  local file = io.open(M.fullpath(self, projects), "r")

  if not file then
    return { has_msg = true, msg = prefix .. "file not found", changed = false }
  end

  local new_line_no = -1
  local line_no = 0

  for line in file:lines() do
    line_no = line_no + 1

    if line == self.content then
      if new_line_no == -1 then
        new_line_no = line_no
        if new_line_no == self.location.line then
          file:close()
          return { has_msg = false, msg = "", changed = false }
        end
      else
        file:close()
        return { has_msg = true, msg = prefix .. "content is not unique", changed = false }
      end
    end
  end

  file:close()

  if new_line_no == -1 then
    return { has_msg = true, msg = prefix .. "content not found", changed = false }
  end

  local msg = string.format("line number changed from %d to %d", self.location.line, new_line_no)
  self.location.line = new_line_no

  return { has_msg = true, msg = prefix .. msg, changed = true }
end

return M
