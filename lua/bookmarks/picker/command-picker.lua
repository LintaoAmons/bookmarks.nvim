local Command = require("bookmarks.commands")

local has_telescope, _ = pcall(require, "telescope")
if not has_telescope then
  error("This picker requires telescope.nvim to be installed")
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")

local M = {}

---Pick a command then execute it
---@param opts? {prompt?: string}
function M.pick_commands(opts)
  opts = opts or {}

  -- Get all commands from the Command module
  local commands = {}
  for name, func in pairs(Command.get_all_commands()) do
    if type(func) == "function" then
      table.insert(commands, {
        name = name,
        execute = func,
      })
    end
  end

  pickers
    .new(opts, {
      prompt_title = opts.prompt or "Bookmarks Commands",
      finder = finders.new_table({
        results = commands,
        entry_maker = function(command)
          return {
            value = command,
            display = command.name,
            ordinal = command.name,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selected = action_state.get_selected_entry()
          if selected == nil then
            return
          end
          selected.value.execute()
        end)

        return true
      end,
    })
    :find()
end

return M
