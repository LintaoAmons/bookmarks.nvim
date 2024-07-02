local repo = require("bookmarks.repo")
local utils = require("bookmarks.utils")
local common = require("bookmarks.adapter.common")
local api = require("bookmarks.api")

local function add_list()
  vim.ui.input({ prompt = "Enter BookmarkList name" }, function(input)
    if not input then
      return
    end
    if utils.trim(input) == "" then
      return vim.notify("Require a valid name")
    end
    require("bookmarks.api").add_list({ name = input })
  end)
end

local function mark_to_list()
  local bookmark_lists = repo.bookmark_list.read.find_all()
  vim.ui.input({ prompt = "Enter Bookmark name" }, function(name)
    vim.ui.select(bookmark_lists, {
      prompt = "select the bookmark list to put in",
      ---@param bookmark_list Bookmarks.BookmarkList
      ---@return string
      format_item = function(bookmark_list)
        return bookmark_list.name
      end,
    }, function(bookmark_list)
      ---@cast bookmark_list  Bookmarks.BookmarkList
      if not bookmark_list then
        return
      end

      local param = {
        name = name or "",
        list_name = bookmark_list.name,
      }
      api.mark(param)
    end)
  end)
end

local function goto_bookmark()
  local bookmark_list = repo.bookmark_list.write.find_or_set_active()

  table.sort(bookmark_list.bookmarks, function(a, b)
    return a.created_at > b.created_at
  end)

  vim.ui.select(bookmark_list.bookmarks, {
    prompt = "Selete bookmark from active list: " .. bookmark_list.name,
    format_item = function(item)
      ---@cast item Bookmarks.Bookmark
      return common.format(item, bookmark_list.bookmarks)
    end,
  }, function(choice)
    if not choice then
      return
    end
    ---@cast choice Bookmarks.Bookmark
    api.goto_bookmark(choice)
  end)
end

local function set_active_list()
  local bookmark_lists = repo.bookmark_list.read.find_all()

  vim.ui.select(bookmark_lists, {
    prompt = "Set active list",
    format_item = function(item)
      ---@cast item Bookmarks.BookmarkList
      if item.is_active then
        return "Active: " .. item.name
      end
      return item.name
    end,
  }, function(choice)
    if not choice then
      return
    end
    ---@cast choice Bookmarks.BookmarkList
    api.set_active_list(choice.name)
  end)
end

-- TODO: Telescope version
local function goto_bookmark_in_list()
  local bookmark_lists = repo.bookmark_list.read.find_all()
  vim.ui.select(bookmark_lists, {
    prompt = "select the bookmark list",
    format_item = function(bookmark_list)
      return bookmark_list.name
    end,
  }, function(bookmark_list)
    ---@cast bookmark_list  Bookmarks.BookmarkList
    if not bookmark_list then
      return
    end

    vim.ui.select(bookmark_list.bookmarks, {
      prompt = "Select bookmark",
      format_item = function(bookmark)
        return common.format(bookmark, bookmark_list.bookmarks)
      end,
    }, function(choice)
      if not choice then
        return
      end
      api.goto_bookmark(choice)
    end)
  end)
end

return {
  add_list = add_list,
  mark_to_list = mark_to_list,
  goto_bookmark = goto_bookmark,
  set_active_list = set_active_list,
  goto_bookmark_in_list = goto_bookmark_in_list,
}
