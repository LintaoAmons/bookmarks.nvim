local M = {}
local GROUP_NAME = "BookmarksNvimAutoCmd"

M.setup = function()
  vim.api.nvim_create_augroup(GROUP_NAME, { clear = true })

  vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
    pattern = { "*" },
    group = GROUP_NAME,
    callback = function()
      if vim.g.bookmarks_config and vim.g.bookmarks_config.auto_calibrate_cur_buf then
        require("bookmarks.api").calibrate_current_window()
      else
        require("bookmarks.sign").refresh_signs()
      end
    end,
  })
end
return M
