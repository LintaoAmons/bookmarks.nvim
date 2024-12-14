local M = {}
local GROUP_NAME = "BookmarksNvimAutoCmd"

M.setup = function()
  vim.api.nvim_create_augroup(GROUP_NAME, { clear = true })

  vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
    pattern = { "*" },
    group = GROUP_NAME,

    callback = function()
      if vim.g.bookmarks_config and vim.g.calibrate and vim.g.bookmarks_config.calibrate.auto_calibrate_cur_buf then
        require("bookmarks.calibrate").calibrate_current_window()
        require("bookmarks.sign").safe_refresh_signs()
      else
        require("bookmarks.sign").safe_refresh_signs()
      end
    end,
  })
end

return M
