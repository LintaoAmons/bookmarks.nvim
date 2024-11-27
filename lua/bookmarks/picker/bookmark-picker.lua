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

---Pick a *bookmark* then call the callback function against it
---e.g.
---:lua require("bookmarks.picker").pick_bookmark(function(bookmark) vim.print(bookmark.name) end)
---@param callback fun(bookmark: Bookmarks.Node): nil
---@param opts? {prompt?: string}
function M.pick_bookmark(callback, opts)
  opts = opts or {}

  local function start_picker(_bookmarks, list)
    pickers
      .new(opts, {
        prompt_title = opts.prompt or ("Bookmarks in [" .. list.name .. "] "),
        finder = finders.new_table({
          results = _bookmarks,
          ---@param bookmark Bookmarks.Node
          entry_maker = function(bookmark)
            local display = bookmark.name .. " " .. bookmark.location.path
            return {
              value = bookmark,
              display = display,
              ordinal = display,
              filename = bookmark.location.path,
              col = bookmark.location.col,
              lnum = bookmark.location.line,
            }
          end,
        }),
        sorter = conf.generic_sorter(opts),
        previewer = conf.grep_previewer(opts),
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
            local active_list = Repo.get_active_list()
            start_picker(Node.get_all_bookmarks(active_list), active_list)
          end)

          return true
        end,
      })
      :find()
  end

  local active_list = Repo.get_active_list()
  start_picker(Node.get_all_bookmarks(active_list), active_list)
end

return M
