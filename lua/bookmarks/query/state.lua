local M = {}

---@class Bookmarks.QueryCtx
M._cache = {
  ---@type PresentView
  view = nil,
  ---@type Bookmarks.Query
  query = {},
  ---@type Bookmarks.Node[]
  data = {},
}

M.reset = function()
  M._cache.view = nil
  M._cache.query = {type = "bookmark"}
  M._cache.data = {}
end

M.reset_query = function()
  M._cache.query = {type = "bookmark"}
end

return M
