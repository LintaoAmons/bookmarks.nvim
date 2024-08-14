local repo = require("bookmarks.repo")
local sign = require("bookmarks.sign")
local domain = require("bookmarks.domain")
local utils = require("bookmarks.utils")
local get_hooks = require("bookmarks.hook").get_hooks
local TRIGGER_POINT = require("bookmarks.hook").TRIGGER_POINT

---@class Bookmarks.MarkParam
---@field name string
---@field list_name? string

---@param param Bookmarks.MarkParam
local function mark(param)
  local bookmark = domain.bookmark.new_bookmark(param.name)
  local bookmark_lists = repo.bookmark_list.read.find_all()

  local projects = repo.project.findall()
  local new_project = domain.project.register_new(projects, bookmark.location.project_name)
  if new_project then
    repo.project.save(new_project)
    projects = repo.project.findall()
  end

  local target_bookmark_list
  if param.list_name then
    target_bookmark_list = repo.bookmark_list.read.must_find_by_name(param.list_name)
  else
    target_bookmark_list = repo.bookmark_list.write.find_or_set_active(bookmark_lists)
  end

  local updated_bookmark_list = domain.bookmark_list.toggle_bookmarks(target_bookmark_list, bookmark, projects)

  repo.bookmark_list.write.save(updated_bookmark_list, bookmark_lists)

  sign.refresh_signs()
end

---@class Bookmarks.NewListParam
---@field name string

---@param param Bookmarks.NewListParam
---@return Bookmarks.BookmarkList
local function add_list(param)
  local bookmark_lists = repo.bookmark_list.read.find_all()
  local new_lists = vim.tbl_map(function(value)
    ---@cast value Bookmarks.BookmarkList
    value.is_active = false
    return value
  end, bookmark_lists)

  ---@type Bookmarks.BookmarkList
  local new_list = domain.bookmark_list.new(param.name, utils.generate_datetime_id())

  table.insert(new_lists, new_list)
  repo.bookmark_list.write.save_all(new_lists)

  sign.refresh_signs()
  return new_list
end

---@param name string
local function set_active_list(name)
  local bookmark_lists = repo.bookmark_list.read.find_all()

  local updated = vim.tbl_map(function(value)
    ---@cast value Bookmarks.BookmarkList
    if value.name == name then
      value.is_active = true
    else
      value.is_active = false
    end
    return value
  end, bookmark_lists)
  repo.bookmark_list.write.save_all(updated)

  sign.refresh_signs()
end

---@param bookmark Bookmarks.Bookmark
---@param opts? {open_method?: string}
local function goto_bookmark(bookmark, opts)
  opts = opts or {}
  local open_method = opts.open_method or "e"
  local projects = repo.project.findall()
  local fullpath = domain.bookmark.fullpath(bookmark, projects)

  local curren_bufnr = vim.api.nvim_get_current_buf()
  -- check if the buffer have unsaved changes
  if vim.api.nvim_buf_get_option(curren_bufnr, "modified") then
    utils.log("Please save the current buffer before goto bookmark", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_exec2(open_method .. " " .. fullpath, {})

  pcall(vim.api.nvim_win_set_cursor, 0, { bookmark.location.line, bookmark.location.col })
  vim.cmd("norm! zz")
  bookmark.visited_at = os.time()
  repo.mark.write.save(bookmark)

  local hooks = get_hooks(vim.g.bookmarks_config.hooks, TRIGGER_POINT.AFTER_GOTO_BOOKMARK)
  for _, hook in ipairs(hooks) do
    hook(bookmark, projects)
  end

  sign.refresh_signs()
end

local function goto_last_visited_bookmark()
  local bookmark_list = repo.bookmark_list.write.find_or_set_active()
  table.sort(bookmark_list.bookmarks, function(a, b)
    if a.visited_at == nil or b.visited_at == nil then
      return false
    end
    return a.visited_at > b.visited_at
  end)

  local last_bookmark = bookmark_list.bookmarks[1]
  if last_bookmark then
    goto_bookmark(last_bookmark)
  end

  sign.refresh_signs()
end

-- TODO: trigger by `BufferEnter` Event
local function add_recent()
  local bookmark = domain.bookmark.new_bookmark()
  local recent_files_bookmark_list = repo.get_recent_files_bookmark_list()
  table.insert(recent_files_bookmark_list.bookmarks, bookmark)
  repo.bookmark_list.write.save(recent_files_bookmark_list)
end

local function goto_next_in_current_buffer()
  vim.notify("todo")
  -- get bookmarks of current buf of current active list
  -- get current cursor position
  -- goto the nearest next bookmark
  -- if no next bookmark, then go to the first bookmark
end

local function goto_prev_in_current_buffer()
  vim.notify("todo")
  -- get bookmarks of current buf of current active list
  -- get current cursor position
  -- goto the nearest prev bookmark
  -- if no prev bookmark, then go to the last bookmark
end

---@param id number
---@param new_name string
local function rename_bookmark(id, new_name)
  local bookmark = repo.mark.read.must_find_by_id(id)
  bookmark.name = new_name
  repo.mark.write.save(bookmark)
end

---@param new_name string
---@param bookmark_list_name string
local function rename_bookmark_list(new_name, bookmark_list_name)
  local bookmark_lists = repo.bookmark_list.read.find_all()
  for _, list in ipairs(bookmark_lists) do
    if list.name == new_name then
      utils.log("Can't rename list to name " .. new_name .. " Since there's already a list have that name")
    end
  end
  local bookmark_list = repo.bookmark_list.read.must_find_by_name(bookmark_list_name)
  local old_name = bookmark_list.name
  bookmark_list.name = new_name
  repo.bookmark_list.write.save(bookmark_list)
  repo.bookmark_list.write.delete(old_name)
end

local function find_existing_bookmark_under_cursor()
  local bookmark_list = repo.bookmark_list.write.find_or_set_active()
  return domain.bookmark_list.find_bookmark_by_location(bookmark_list, domain.location.get_current_location())
end

local function reload_bookmarks()
  vim.g.bookmarks_cache = nil
end

local function calibrate_current_window()
  local cur_buf = vim.api.nvim_get_current_buf()
  local cur_path = vim.api.nvim_buf_get_name(cur_buf)
  local bookmark_list = repo.bookmark_list.write.find_or_set_active()
  if not bookmark_list then
    return
  end

  local projects = repo.project.findall()
  local bookmarks = domain.bookmark_list.find_bookmarks_by_abs_path(bookmark_list, cur_path, projects)
  if #bookmarks == 0 then
    return
  end

  local changed = false
  for _, bookmark in ipairs(bookmarks) do
    local ret = domain.bookmark.calibrate(bookmark, projects)
    if ret.changed then
      changed = true
    end
  end

  if not changed then
    return
  end
  vim.print("Calibrated " .. #bookmarks .. " bookmarks in current buffer")
  repo.bookmark_list.write.save(bookmark_list)
  sign.refresh_signs()
  sign.refresh_tree()
end

local function calibrate_bookmarks()
  local bookmark_lists = repo.bookmark_list.read.find_all()
  local projects = repo.project.findall()
  local results = {}
  local highlights = {}
  local line_no = -1
  for _, list in ipairs(bookmark_lists) do
    for _, bookmark in ipairs(domain.bookmark_list.get_all_marks(list)) do
      local ret = domain.bookmark.calibrate(bookmark, projects)
      if ret.has_msg then
        table.insert(results, ret.msg)
        line_no = line_no + 1
      end

      if ret.changed then
        table.insert(highlights, line_no)
      end
    end
  end

  repo.bookmark_list.write.save_all(bookmark_lists)
  sign.refresh_signs()
  sign.refresh_tree()

  if not vim.g.bookmarks_config.show_calibrate_result then
    return
  end

  local temp_buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_lines(temp_buf, 0, -1, false, results)
  vim.bo[temp_buf].buftype = "nofile"
  vim.bo[temp_buf].modifiable = false

  vim.api.nvim_set_current_buf(temp_buf)

  local _namespace = sign.namespace
  for _, line in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(temp_buf, _namespace.ns, _namespace.hl_name, line, 0, -1)
  end
end


local function open_bookmarks_jsonfile()
  vim.cmd("e " .. vim.g.bookmarks_config.json_db_path)
end

---@param c string The single character to convert
---@return string The hex representation of that character
local function char_to_hex(c)
  return string.format("%%%02X", string.byte(c))
end

---@param str string The string to encode
---@return string The percent encoded string
local function percent_encode(str)
  if str == nil then
    return ""
  end
  str = str:gsub("\n", "\r\n")

  return (str:gsub("([/\\:*?\"'<>+ |%.%%])", char_to_hex))
end

---@param root_dir string
local function reset_new_db_path(root_dir)
  local dir = vim.fn.stdpath("data") .. "/bookmarks/"
  root_dir = percent_encode(root_dir)
  root_dir = string.format("%s.db.json", root_dir)
  local db_path = dir .. root_dir
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end

  repo.db.reset(db_path)
  sign.refresh_signs()
  sign.refresh_tree()
end

return {
  mark = mark,
  rename_bookmark = rename_bookmark,
  reset_new_db_path = reset_new_db_path,
  add_list = add_list,
  set_active_list = set_active_list,
  rename_bookmark_list = rename_bookmark_list,
  goto_bookmark = goto_bookmark,
  goto_last_visited_bookmark = goto_last_visited_bookmark,
  goto_next_in_current_buffer = goto_next_in_current_buffer,
  goto_prev_in_current_buffer = goto_prev_in_current_buffer,
  add_recent = add_recent,
  find_existing_bookmark_under_cursor = find_existing_bookmark_under_cursor,
  helper = {
    open_bookmarks_jsonfile = open_bookmarks_jsonfile,
  },
  calibrate_bookmarks = calibrate_bookmarks,
  tree = require("bookmarks.tree.api"),
  calibrate_current_window = calibrate_current_window,
}
