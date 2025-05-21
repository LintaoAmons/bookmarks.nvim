-- local Window = require("bookmarks.utils.window")
local Service = require("bookmarks.domain.service")
local Node = require("bookmarks.domain.node")
local Location = require("bookmarks.domain.location")
local Sign = require("bookmarks.sign")
local Tree = require("bookmarks.tree")
-- local Node = require("bookmarks.node")

local M = {}

-- Get user commands from config
local function get_user_commands()
  local cfg = vim.g.bookmarks_config or {}
  return cfg.commands or {}
end

-- Merge built-in and user commands
M.get_all_commands = function()
  local commands = {}
  -- Add built-in commands
  for name, func in pairs(M) do
    if type(func) == "function" and name ~= "get_all_commands" then
      commands[name] = func
    end
  end
  -- Add user commands
  for name, func in pairs(get_user_commands()) do
    commands[name] = func
  end
  return commands
end

M.new_list = function()
  vim.ui.input({ prompt = "[Create new bookmark_list]" }, function(input)
    if input then
      local new_list = Service.create_list(input)
      Sign.safe_refresh_signs()
      pcall(Tree.refresh, new_list.id)
    end
  end)
end

M.current_file_bookmarks_to_new_list = function()
  local filepath = Location.get_current_location().path
  local bookmarks = Service.find_bookmarks_of_file(filepath)

  local new_list = Service.create_list(vim.fn.fnamemodify(filepath, ":t"))
  for _, bookmark in pairs(bookmarks) do
    local new_node = Node.new_from_node(bookmark)
    Service.new_bookmark(new_node, new_list.id)
  end
  Sign.safe_refresh_signs()
  pcall(Tree.refresh, new_list.id)
end

M.delete_mark_of_current_file = function()
  local filepath = Location.get_current_location().path
  if not filepath then
    vim.notify("No file path found", vim.log.levels.ERROR)
    return
  end

  local query_api = require("bookmarks.query.query")
  local success = query_api.eval(string.format("DELETE FROM nodes WHERE location_path = '%s'", filepath))

  if success then
    vim.notify(string.format("Deleted marks from %s", vim.fn.fnamemodify(filepath, ":t")), vim.log.levels.INFO)
  else
    vim.notify("Failed to delete marks", vim.log.levels.ERROR)
  end
  Sign.safe_refresh_signs()
end

M.mix_active_bookmark = function()
  require("bookmarks.mix").mix_active_list({ open = true, notify = true })
end

M.mark_selected_files = function()
  require("bookmarks.domain.service").mark_selected_files()
end

M["Show info of current bookmark"] = function()
  require("bookmarks.info").show_bookmark_info()
end

M["Link bookmark"] = function()
  local bookmark = Service.find_bookmark_by_location()
  if not bookmark then
    vim.notify("No bookmark found at current location", vim.log.levels.ERROR)
    return
  end
  require("bookmarks.picker").pick_bookmark(function(target_bookmark)
    if target_bookmark and target_bookmark.id ~= bookmark.id then
      Service.link_bookmarks(bookmark.id, target_bookmark.id)
    elseif target_bookmark then
      vim.notify("Cannot link a bookmark to itself", vim.log.levels.ERROR)
    end
  end, { prompt = "Select bookmark to link to" })
end

M["Goto linked out bookmarks"] = function()
  local bookmark = Service.find_bookmark_by_location()
  if not bookmark then
    vim.notify("No bookmark found at current location", vim.log.levels.ERROR)
    return
  end
  local linked_bookmarks = Service.get_linked_out_bookmarks(bookmark.id)
  if #linked_bookmarks == 0 then
    vim.notify("No linked bookmarks found", vim.log.levels.INFO)
    return
  end
  require("bookmarks.picker").pick_bookmark(function(selected)
    if selected then
      Service.goto_bookmark(selected.id)
      Sign.safe_refresh_signs()
    end
  end, { prompt = "Linked Bookmarks for " .. bookmark.name, bookmarks = linked_bookmarks })
end

M["Goto linked in bookmarks"] = function()
  local bookmark = Service.find_bookmark_by_location()
  if not bookmark then
    vim.notify("No bookmark found at current location", vim.log.levels.ERROR)
    return
  end
  local linked_in_bookmarks = Service.get_linked_in_bookmarks(bookmark.id)
  if #linked_in_bookmarks == 0 then
    vim.notify("No bookmarks linking to this bookmark", vim.log.levels.INFO)
    return
  end
  require("bookmarks.picker").pick_bookmark(function(selected)
    if selected then
      Service.goto_bookmark(selected.id)
      Sign.safe_refresh_signs()
    end
  end, { prompt = "Bookmarks Linking to " .. bookmark.name, bookmarks = linked_in_bookmarks })
end

M["Mark and link to existing bookmark"] = function()
  vim.ui.input({ prompt = "[Bookmark Name]" }, function(input)
    if input then
      local new_bookmark = Service.toggle_mark(input)
      if new_bookmark then
        require("bookmarks.picker").pick_bookmark(function(target_bookmark)
          if target_bookmark and target_bookmark.id ~= new_bookmark.id then
            Service.link_bookmarks(new_bookmark.id, target_bookmark.id)
          elseif target_bookmark then
            vim.notify("Cannot link a bookmark to itself", vim.log.levels.ERROR)
          end
        end, { prompt = "Select bookmark to link to" })
      end
      Sign.safe_refresh_signs()
      pcall(Tree.refresh)
    end
  end)
end

return M
