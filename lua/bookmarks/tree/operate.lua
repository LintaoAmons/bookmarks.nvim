local api = require("bookmarks.api")

local M = {}

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

return M
