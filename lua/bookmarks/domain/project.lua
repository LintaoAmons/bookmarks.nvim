local utils = require("bookmarks.utils")

---@class Bookmarks.Project
---@field name string
---@field path string

local M = {}

---@param name string
---@param path string?
---@return Bookmarks.Project
function M.new(name, path)
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
  function M.register_new(existing, name, path)
    for _, p in ipairs(existing) do
      if p.name == name then
        return
      end
    end
    return M.new(name, path)
  end

return M
