local Repo = require("bookmarks.domain.repo")
local Service = require("bookmarks.domain.service")
local Node = require("bookmarks.domain.node")
local Actions = require("bookmarks.picker.actions")

local has_telescope, _ = pcall(require, "telescope")
if not has_telescope then
  error("This picker requires telescope.nvim to be installed")
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")
local action_set = require("telescope.actions.set")

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
          -- <C-x>	Go to file selection as a split
          -- <C-v>	Go to file selection as a vsplit
          -- <C-t>	Go to a file in a new tab
          actions.select_horizontal:replace(function()
            Actions.open_in_split(prompt_bufnr)
          end)

          actions.select_vertical:replace(function()
            Actions.open_in_vsplit(prompt_bufnr)
          end)

          actions.select_tab:replace(function()
            Actions.open_in_new_tab(prompt_bufnr)
          end)

          map("i", "<c-d>", function()
            Actions.delete(prompt_bufnr)
            local active_list = Repo.ensure_and_get_active_list()
            start_picker(Node.get_all_bookmarks(active_list), active_list)
          end)

          return true
        end,
      })
      :find()
  end

  local active_list = Repo.ensure_and_get_active_list()
  start_picker(Node.get_all_bookmarks(active_list), active_list)
end

---Grep through the content of all bookmarked files
---@param opts? table
function M.grep_bookmark(opts)
  opts = opts or {}
  local active_list = Repo.ensure_and_get_active_list()
  local bookmarks = Node.get_all_bookmarks(active_list)

  -- Get unique file paths from bookmarks
  local files = {}
  local seen = {}
  for _, bookmark in ipairs(bookmarks) do
    if not seen[bookmark.location.path] then
      seen[bookmark.location.path] = true
      table.insert(files, bookmark.location.path)
    end
  end

  -- Configure picker with live_grep
  local live_grep_opts = {
    prompt_title = "Grep Bookmarked Files",
    search_dirs = files,
    additional_args = function()
      return { "--hidden" }
    end,
  }

  require("telescope.builtin").live_grep(vim.tbl_extend("force", live_grep_opts, opts))
end

return M
