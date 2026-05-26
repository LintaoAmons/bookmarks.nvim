local function get_backend()
  local cfg = vim.g.bookmarks_config
  return cfg and cfg.picker and cfg.picker.picker_backend or "snacks"
end

local function get_picker(module)
  local backend = get_backend()
  if backend == "snacks" then
    return require("bookmarks.picker.snacks." .. module)
  else
    return require("bookmarks.picker.telescope." .. module)
  end
end

return {
  pick_bookmark = function(...)
    return get_picker("bookmark-picker").pick_bookmark(...)
  end,
  grep_bookmark = function(...)
    return get_picker("bookmark-picker").grep_bookmark(...)
  end,
  pick_bookmark_list = function(...)
    return get_picker("list-picker").pick_bookmark_list(...)
  end,
  pick_commands = function(...)
    return get_picker("command-picker").pick_commands(...)
  end,
}
