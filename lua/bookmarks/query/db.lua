local DB = require("sqlite.db")
local Repo = require("bookmarks.domain.repo")

local M = {}

--- require("bookmarks.query.api").query("select * from nodes")
---execute a query
---@param query string
---@return Bookmarks.Node[]
M.query = function(query)
  local db = DB:open(Repo._DB.uri)
  local result = db:eval(query)
  vim.print(result)
end

return M
