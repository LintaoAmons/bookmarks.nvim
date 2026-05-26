local Repo = require("bookmarks.domain.repo")
local Service = require("bookmarks.domain.service")
local Node = require("bookmarks.domain.node")

local M = {}

local function format_entry(bookmark, bookmarks)
  local max_name = 15
  local max_filename = 20

  for _, bm in ipairs(bookmarks) do
    max_name = math.max(max_name, #bm.name)
    local filename = vim.fn.fnamemodify(bm.location.path, ":t")
    max_filename = math.max(max_filename, #filename)
  end

  max_name = math.min(max_name, 30)
  max_filename = math.min(max_filename, 30)

  local name = bookmark.name
  local filename = vim.fn.fnamemodify(bookmark.location.path, ":t")

  if #name > max_name then
    name = name:sub(1, max_name - 2) .. ".."
  else
    name = name .. string.rep(" ", max_name - #name)
  end

  if #filename > max_filename then
    filename = filename:sub(1, max_filename - 2) .. ".."
  else
    filename = filename .. string.rep(" ", max_filename - #filename)
  end

  return string.format("%s │ %s", name, filename)
end

---@param callback fun(bookmark: Bookmarks.Node): nil
---@param opts? {prompt?: string, bookmarks?: Bookmarks.Node[]}
function M.pick_bookmark(callback, opts)
  opts = opts or {}

  local active_list = Repo.ensure_and_get_active_list()
  local bookmarks = opts.bookmarks or Node.get_all_bookmarks(active_list)
  local list_name = opts.bookmarks and "Custom Selection" or active_list.name

  local entry_display = vim.g.bookmarks_config.picker.entry_display or format_entry

  local items = {}
  for _, bookmark in ipairs(bookmarks) do
    table.insert(items, {
      text = entry_display(bookmark, bookmarks),
      file = bookmark.location.path,
      pos = { bookmark.location.line, bookmark.location.col },
      bookmark = bookmark,
    })
  end

  Snacks.picker({
    title = opts.prompt or ("Bookmarks in [" .. list_name .. "]"),
    items = items,
    format = "file",
    preview = "file",
    confirm = function(picker, item)
      picker:close()
      if item then
        callback(item.bookmark)
      end
    end,
    actions = {
      delete_bookmark = function(picker, item)
        if not item or not item.bookmark then
          return
        end
        Service.delete_node(item.bookmark.id)
        picker:close()
        -- Reopen with updated bookmarks
        vim.schedule(function()
          M.pick_bookmark(callback, opts)
        end)
      end,
    },
    win = {
      input = {
        keys = {
          ["<C-d>"] = { "delete_bookmark", mode = { "i", "n" }, desc = "Delete bookmark" },
        },
      },
    },
  })
end

---@param opts? table
function M.grep_bookmark(opts)
  opts = opts or {}
  local active_list = Repo.ensure_and_get_active_list()
  local bookmarks = Node.get_all_bookmarks(active_list)

  local dirs = {}
  local seen = {}
  for _, bookmark in ipairs(bookmarks) do
    if not seen[bookmark.location.path] then
      seen[bookmark.location.path] = true
      table.insert(dirs, bookmark.location.path)
    end
  end

  Snacks.picker.grep({
    title = "Grep Bookmarked Files",
    dirs = dirs,
  })
end

return M
