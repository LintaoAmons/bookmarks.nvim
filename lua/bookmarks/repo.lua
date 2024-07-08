local json = require("bookmarks.json")
local utils = require("bookmarks.utils")

---@class Bookmarks.DB
---@field bookmark_lists Bookmarks.BookmarkList[]
---@field projects Bookmarks.Project[]

---@return Bookmarks.DB
local get_db = function()
  if vim.g.bookmarks_cache then
    return vim.g.bookmarks_cache
  end

  local ok, result =
    pcall(json.read_or_init_json_file, vim.g.bookmarks_config.json_db_path, { projects = {}, bookmark_lists = {} })
  if not ok or not result.projects or not result.bookmark_lists then
    utils.log(
      "Incorrect config, please check your config file at: "
        .. vim.g.bookmarks_config.json_db_path
        .. "\nor just remove it (all your bookmarks will disappear)"
    )
    vim.g.bookmarks_cache = result
    return result
  end
end

---@param domain Bookmarks.DB
local save_db = function(domain)
  vim.g.bookmarks_cache = domain
  json.write_json_file(domain, vim.g.bookmarks_config.json_db_path)
end

---@param bookmark_lists Bookmarks.BookmarkList[]
local save_all = function(bookmark_lists)
  local db = get_db()
  db.bookmark_lists = bookmark_lists
  save_db(db)
end

-- Function to generate an ID in the datetime format
local function generate_datetime_id()
  -- Get the current date and time in the desired format
  local datetime = os.date("%Y%m%d%H%M%S")

  -- Generate a random number (e.g., using math.random) and append it to the datetime
  local random_suffix = ""
  for _ = 1, 8 do
    random_suffix = random_suffix .. tostring(math.random(0, 9))
  end

  -- Concatenate the datetime and random suffix to create the ID
  local id = datetime .. random_suffix

  return id
end

---@return Bookmarks.BookmarkList[]
local function find_all()
  return get_db().bookmark_lists or {}
end

---@param bookmark_lists? Bookmarks.BookmarkList[]
---@return Bookmarks.BookmarkList
local function find_or_set_active_bookmark_list(bookmark_lists)
  bookmark_lists = bookmark_lists or find_all()
  local active_bookmark_list = nil

  -- Check if there's an active BookmarkList
  for _, bookmark_list in ipairs(bookmark_lists) do
    if bookmark_list.is_active then
      active_bookmark_list = bookmark_list
      break
    end
  end

  -- If no active BookmarkList was found, mark the first one as active
  if not active_bookmark_list and #bookmark_lists > 0 then
    bookmark_lists[1].is_active = true
    active_bookmark_list = bookmark_lists[1]
  end

  -- If there are no BookmarkLists, create a new one
  if not active_bookmark_list then
    -- TODO: use domain logic to create new one
    active_bookmark_list = {
      id = generate_datetime_id(),
      name = "Default",
      is_active = true,
      bookmarks = {},
    }
    table.insert(bookmark_lists, active_bookmark_list)
  end

  return active_bookmark_list
end

---@param bookmark_list_name string
---@param bookmark_lists? Bookmarks.BookmarkList[]
---@return Bookmarks.BookmarkList
local function must_find_bookmark_list_by_name(bookmark_list_name, bookmark_lists)
  bookmark_lists = bookmark_lists or find_all()

  local found = vim.tbl_filter(function(bookmark_list)
    ---@cast bookmark_list Bookmarks.BookmarkList
    return bookmark_list.name == bookmark_list_name
  end, bookmark_lists)

  if #found == 1 then
    return found[1]
  elseif #found == 0 then
    error("Can't found bookmark list by name ")
  else
    error(
      "More than one bookmark list have the name "
        .. bookmark_list_name
        .. ". Please clean your json db manually at "
        .. vim.g.bookmarks_config.json_db_path
    )
  end
end

---@return Bookmarks.BookmarkList
local function get_recent_files_bookmark_list()
  local name = "RecentFiles"
  local bookmark_lists = find_all()
  local found = vim.tbl_filter(function(bookmark_list)
    ---@cast bookmark_list Bookmarks.BookmarkList
    return bookmark_list.name == name
  end, bookmark_lists)

  if #found == 1 then
    return found[1]
  elseif #found == 0 then
    return {
      id = generate_datetime_id(),
      name = name,
      is_active = false,
      bookmarks = {},
    }
  else
    error(
      "More than one bookmark list have the name "
        .. name
        .. ". Please clean your json db manually at "
        .. vim.g.bookmarks_config.json_db_path
    )
  end
end

---@param bookmark_list Bookmarks.BookmarkList
---@param bookmark_lists? Bookmarks.BookmarkList[]
local function save_bookmark_list(bookmark_list, bookmark_lists)
  local db = get_db()
  bookmark_lists = bookmark_lists or db.bookmark_lists
  local new_bookmark_lists = vim.tbl_filter(function(bl)
    return bl.name ~= bookmark_list.name
  end, bookmark_lists)
  table.insert(new_bookmark_lists, bookmark_list)
  db.bookmark_lists = new_bookmark_lists

  save_db(db)
end

---@param bookmark Bookmarks.Bookmark
---@param bookmark_list? Bookmarks.BookmarkList
local function save_bookmark(bookmark, bookmark_list)
  bookmark_list = bookmark_list or find_or_set_active_bookmark_list()
  local new_bookmarks = vim.tbl_filter(function(b)
    return b.created_at ~= bookmark.created_at
  end, bookmark_list.bookmarks)
  table.insert(new_bookmarks, bookmark)
  bookmark_list.bookmarks = new_bookmarks
  save_bookmark_list(bookmark_list)
end

---@param bookmark Bookmarks.Bookmark
---@param bookmark_list? Bookmarks.BookmarkList
local function delete_bookmark(bookmark, bookmark_list)
  bookmark_list = bookmark_list or find_or_set_active_bookmark_list()
  local new_bookmarks = vim.tbl_filter(function(b)
    return b.created_at ~= bookmark.created_at
  end, bookmark_list.bookmarks)
  bookmark_list.bookmarks = new_bookmarks
  save_bookmark_list(bookmark_list)
end

---@param name string
local function delete_bookmark_list(name)
  local db = get_db()
  local bookmark_lists = db.bookmark_lists
  local new_bookmark_lists = vim.tbl_filter(function(bl)
    return bl.name ~= name
  end, bookmark_lists)
  db.bookmark_lists = new_bookmark_lists
  save_db(db)
end

---@param id number
local function must_find_bookmark_by_id(id)
  local bookmark_lists = find_all()
  for _, list in ipairs(bookmark_lists) do
    for _, bookmark in ipairs(list.bookmarks) do
      if bookmark.id == id then
        return bookmark
      end
    end
  end
  error("Can't find the bookmark with id: " .. id)
end

---@return Bookmarks.Bookmark[]
local function find_all_bookmarks()
  local bookmark_lists = find_all()
  local all = {}
  for _, bookmark_list in pairs(bookmark_lists) do
    for _, bookmark in ipairs(bookmark_list.bookmarks) do
      bookmark.listname = bookmark_list.name
      table.insert(all, bookmark)
    end
  end
  return all
end

local project_repo = (function()
  local PROJECT_REPO = {}

  ---@param project Bookmarks.Project
  function PROJECT_REPO.save(project)
    local db = get_db()
    table.insert(db.projects, project)
    save_db(db)
  end

  ---@return Bookmarks.Project[]
  function PROJECT_REPO.findall()
    return get_db().projects
  end

  return PROJECT_REPO
end)()

-- pcall read method and display hint about correputed json file
return {
  db = {
    get = get_db,
  },
  bookmark_list = {
    read = {
      find_all = find_all,
      must_find_by_name = must_find_bookmark_list_by_name,
    },
    write = {
      save = save_bookmark_list,
      save_all = save_all,
      find_or_set_active = find_or_set_active_bookmark_list,
      delete = delete_bookmark_list,
    },
  },
  mark = {
    read = {
      must_find_by_id = must_find_bookmark_by_id,
      find_all = find_all_bookmarks,
    },
    write = {
      save = save_bookmark,
      delete = delete_bookmark,
    },
  },
  project = project_repo,

  -- read
  get_recent_files_bookmark_list = get_recent_files_bookmark_list,

  generate_datetime_id = generate_datetime_id,
}
