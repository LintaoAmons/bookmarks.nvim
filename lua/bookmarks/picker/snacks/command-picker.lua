local Command = require("bookmarks.commands")

local M = {}

---@param opts? {prompt?: string}
function M.pick_commands(opts)
  opts = opts or {}

  local commands = {}
  for name, func in pairs(Command.get_all_commands()) do
    if type(func) == "function" then
      table.insert(commands, {
        text = name,
        execute = func,
      })
    end
  end

  Snacks.picker({
    title = opts.prompt or "Bookmarks Commands",
    items = commands,
    confirm = function(picker, item)
      picker:close()
      if item then
        item.execute()
      end
    end,
  })
end

return M
