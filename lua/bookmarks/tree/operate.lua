local api = require("bookmarks.api")
local sign = require("bookmarks.sign")

local M = {}

---@param name string
---@param line_no number
function M.create_folder_with_info(name, line_no)
  api.tree.create_folder(name, line_no)
end

function M.create_folder()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]

  vim.ui.input({ prompt = "add folder:", default = "" }, function(input)
    if input then
      M.create_folder_with_info(input, line_no)
    end
  end)
end

function M.tree_cut()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]
  api.tree.cut(line_no)
end

function M.copy()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]
  api.tree.copy(line_no)
end

function M.tree_paste()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]
  api.tree.paste(line_no)
end

function M.collapse()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]
  local bookmark = api.tree.collapse(line_no)
  local ctx = vim.g.bookmark_list_win_ctx
  if not ctx then
    return
  end

  if bookmark then
    vim.api.nvim_set_current_win(ctx.previous_window)
    require("bookmarks.api").goto_bookmark(bookmark)
  end
end

function M.delete()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]
  api.tree.delete(line_no)
end

function M.quit()
  local ctx = vim.g.bookmark_list_win_ctx
  vim.api.nvim_win_close(ctx.win, true)
  vim.g.bookmark_list_win_ctx = nil
end

function M.active()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]
  local ctx = vim.b._bm_context.line_contexts[line_no]
  api.set_active_list(ctx.root_name)
  sign.refresh_tree()
end

-- function M.open()
--   local line_no = vim.api.nvim_win_get_cursor(0)[1]
--   api.tree.open(line_no)
-- end

return M
