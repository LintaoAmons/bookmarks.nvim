local Repo = require("bookmarks.domain.repo")
local Service = require("bookmarks.domain.service")
local Node = require("bookmarks.domain.node")

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

---Pick a *bookmark_list* then call the callback function against it
---e.g.
---:lua require("bookmarks.picker").pick_bookmark_list(function(list) vim.print(bookmark.name) end)
---@param callback fun(list: Bookmarks.Node): nil
---@param opts? {prompt?: string}
function M.pick_bookmark_list(callback, opts)
  opts = opts or {}

  local function start_picker(_lists)
    pickers
      .new(opts, {
        prompt_title = opts.prompt or "Bookmark Lists: ",
        finder = finders.new_table({
          results = _lists,
          ---@param list Bookmarks.Node
          entry_maker = function(list)
            local display = list.name
            return {
              value = list,
              display = display,
              ordinal = display,
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
            callback(selected.value)
          end)

          map("i", "<c-d>", function()
            ---@type Bookmarks.Node
            local selected = action_state.get_selected_entry().value
            Service.delete_node(selected.id)
            actions.close(prompt_bufnr)
            start_picker(Repo.find_lists())
          end)

          --- TODO: set active list action

          return true
        end,
      })
      :find()
  end

  start_picker(Repo.find_lists())
end
return M
