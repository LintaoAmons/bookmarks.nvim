-- TODO: add more sort logics

local M = {
  last_visited = function(bookmarks)
    table.sort(bookmarks, function(a, b)
      return a.visited_at > b.visited_at
    end)
  end,
  created_at = function(bookmarks)
    table.sort(bookmarks, function(a, b)
      return a.created_at > b.created_at
    end)
  end,
  identity = function(bookmarks)
    return bookmarks
  end,
}

---@param bookmarks Bookmarks.Bookmark[]
function M.sort_by(bookmarks)
  if vim.g.bookmarks_config.picker and vim.g.bookmarks_config.picker.sort_by then
    if type(vim.g.bookmarks_config.picker.sort_by) == "function" then
      vim.g.bookmarks_config.picker.sort_by(bookmarks)
      return
    elseif type(vim.g.bookmarks_config.picker.sort_by) == "string" and M[vim.g.bookmarks_config.picker.sort_by] then
      M[vim.g.bookmarks_config.picker.sort_by](bookmarks)
      return
    end
  end
  M.last_visited(bookmarks)
end

return M
