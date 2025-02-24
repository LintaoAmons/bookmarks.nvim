local Repo = require("bookmarks.domain.repo")
local Bookmark = require("bookmarks.calibrate.bookmark")

local M = {}

function M.calibrate_current_window()
  local cur_buf = vim.api.nvim_get_current_buf()
  local cur_path = vim.api.nvim_buf_get_name(cur_buf)

  local bookmarks = Repo.find_bookmarks_by_path(cur_path)

  if #bookmarks == 0 then
    return
  end

  local changed_count = 0
  local logs = {}
  for _, bookmark in ipairs(bookmarks) do
    local ret = Bookmark.calibrate(bookmark)
    if ret.changed then
      changed_count = changed_count + 1
    end
    if ret.has_msg then
      table.insert(logs, ret.msg)
    end
  end

  if changed_count == 0 then
    return
  end

  if
    vim.g.bookmarks_config
    and vim.g.bookmarks_config.calibrate
    and vim.g.bookmarks_config.calibrate.show_calibrate_result
  then
    vim.print("Calibrated " .. changed_count .. " bookmarks in current buffer")
    if #logs > 0 then
      vim.print(table.concat(logs, "\n"))
    end
  end

  for _, b in pairs(bookmarks) do
    Repo.update_node(b)
  end
end

-- TODO: bring back this function
-- function M.calibrate_bookmarks()
--   local bookmark_lists = Repo.bookmark_list.read.find_all()
--   local projects = Repo.project.findall()
--   local results = {}
--   local highlights = {}
--   local line_no = -1
--   for _, list in ipairs(bookmark_lists) do
--     for _, bookmark in ipairs(domain.bookmark_list.get_all_marks(list)) do
--       local ret = domain.bookmark.calibrate(bookmark, projects)
--       if ret.has_msg then
--         table.insert(results, ret.msg)
--         line_no = line_no + 1
--       end
--
--       if ret.changed then
--         table.insert(highlights, line_no)
--       end
--     end
--   end
--
--   Repo.bookmark_list.write.save_all(bookmark_lists)
--   sign.refresh_signs()
--   sign.refresh_tree()
--
--   if not vim.g.bookmarks_config.show_calibrate_result then
--     return
--   end
--
--   local temp_buf = vim.api.nvim_create_buf(false, true)
--
--   vim.api.nvim_buf_set_lines(temp_buf, 0, -1, false, results)
--   vim.bo[temp_buf].buftype = "nofile"
--   vim.bo[temp_buf].modifiable = false
--
--   vim.api.nvim_set_current_buf(temp_buf)
--
--   local _namespace = sign.namespace
--   for _, line in ipairs(highlights) do
--     vim.api.nvim_buf_add_highlight(temp_buf, _namespace.ns, _namespace.hl_name, line, 0, -1)
--   end
-- end

return M
