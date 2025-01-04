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

return M
