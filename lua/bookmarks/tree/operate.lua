local api = require("bookmarks.api")

local M = {}

---@param name string
---@param line_no number
function M.create_folder_with_info(name, line_no)
  api.tree.create_folder(name, line_no)
end

function M.create_folder()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]

  vim.ui.input(
    { prompt = "add folder:", default = "" },
    function(input)
      if input then
        M.create_folder_with_info(input, line_no)
      end
    end
  )
end

function M.tree_cut()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]
  api.tree.cut(line_no)
end

function M.tree_paste()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]
  api.tree.paste(line_no)
end


function M.collapse()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]
  api.tree.collapse(line_no)
end


function M.delete()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]
  api.tree.delete(line_no)
end

return M
