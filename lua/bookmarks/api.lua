local repo = require("bookmarks.repo")
local sign = require("bookmarks.sign")
local domain = require("bookmarks.bookmark")
local utils = require("bookmarks.utils")

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
  local new_list = domain.bookmark_list.new(param.name, repo.generate_datetime_id())

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
  vim.api.nvim_exec2(open_method .. " " .. domain.bookmark.fullpath(bookmark, projects), {})
  pcall(vim.api.nvim_win_set_cursor, 0, { bookmark.location.line, bookmark.location.col })
  bookmark.visited_at = os.time()
  repo.mark.write.save(bookmark)
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

local function open_bookmarks_jsonfile()
  vim.cmd("e " .. vim.g.bookmarks_config.json_db_path)
end

return {
  mark = mark,
  rename_bookmark = rename_bookmark,

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
    reload_bookmarks = reload_bookmarks,
    open_bookmarks_jsonfile = open_bookmarks_jsonfile,
  },
}
