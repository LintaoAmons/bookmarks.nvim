local TRIGGER_POINT = {
  AFTER_GOTO_BOOKMARK = "AFTER_GOTO_BOOKMARK",
}

---@class Bookmarks.Hook
---@field callback fun(bookmark: Bookmarks.Bookmark, projects: Bookmarks.Project[])
---@field trigger_point? string

---@param hooks Bookmarks.Hook[]
---@param point string
---@return function[]
local get_hooks = function(hooks, point)
  local matching_hooks = {}
  for _, hook in ipairs(hooks) do
    local trigger_point = hook.trigger_point or TRIGGER_POINT.AFTER_GOTO_BOOKMARK

    if trigger_point == point then
      table.insert(matching_hooks, hook)
    end
  end

  -- Extract and return the callback functions from the matching hooks
  local callbacks = {}
  for _, hook in ipairs(matching_hooks) do
    table.insert(callbacks, hook.callback)
  end

  return callbacks
end

return {
  get_hooks = get_hooks,
  TRIGGER_POINT = TRIGGER_POINT,
}
