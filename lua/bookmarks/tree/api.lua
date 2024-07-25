local repo = require("bookmarks.repo")
local sign = require("bookmarks.sign")
local domain = require("bookmarks.bookmark")


local M = {}

---@param id string | number
---@param name string
function M.create_folder(name, line_no)
  local ctx = vim.b.context.line_contexts[line_no]

  local bookmark_lists = repo.bookmark_list.read.find_all()
  for _, bookmark_list in ipairs(bookmark_lists) do
    if domain.bookmark_list.create_tree_folder(bookmark_list, ctx.id, name) then
      repo.bookmark_list.write.save(bookmark_list)
      break
    end
  end

  sign.refresh_tree()
end

return M
