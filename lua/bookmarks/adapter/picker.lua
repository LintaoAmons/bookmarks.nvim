local repo = require("bookmarks.repo")
local common = require("bookmarks.adapter.common")

-- TODO: check dependencies firstly
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")

---@param callback fun(bookmark_list: Bookmarks.BookmarkList): nil
---@param opts? {prompt?: string}
local function pick_bookmark_list(callback, opts)
  local bookmark_lists = repo.bookmark_list.read.find_all()
  opts = opts or {}
  local prompt = opts.prompt or "Select bookmark list"

  pickers
    .new(opts, {
      prompt_title = prompt,
      finder = finders.new_table({
        results = bookmark_lists,
        ---@param bookmark_list Bookmarks.BookmarkList
        entry_maker = function(bookmark_list)
          return {
            value = bookmark_list,
            display = bookmark_list.name,
            ordinal = bookmark_list.name,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selected = action_state.get_selected_entry().value
          callback(selected)
        end)
        return true
      end,
    })
    :find()

  -- vim.ui.select(bookmark_lists, {
  -- 	prompt = prompt,
  -- 	format_item = function(item)
  -- 		---@cast item Bookmarks.BookmarkList
  -- 		return item.name
  -- 	end,
  -- }, function(choice)
  -- 	---@cast choice Bookmarks.BookmarkList
  -- 	if not choice then
  -- 		return
  -- 	end
  -- 	callback(choice)
  -- end)
end

---@param callback fun(bookmark: Bookmarks.Bookmark): nil
---@param opts? {prompt?: string, bookmark_list?: Bookmarks.BookmarkList, all?: boolean}
local function pick_bookmark(callback, opts)
  opts = opts or {}
  local bookmarks
  local bookmark_list_name
  if opts.all then
    bookmarks = repo.mark.read.find_all()
    bookmark_list_name = "All"
  else
    local bookmark_list = opts.bookmark_list or repo.bookmark_list.write.find_or_set_active()
    bookmark_list_name = bookmark_list.name
    bookmarks = bookmark_list.bookmarks
  end

  table.sort(bookmarks, function(a, b)
    return a.visited_at > b.visited_at
  end)

  pickers
    .new(opts, {
      prompt_title = opts.prompt or ("Bookmarks: [" .. bookmark_list_name .. "]"),
      finder = finders.new_table({
        results = bookmarks,
        ---@param bookmark Bookmarks.Bookmark
        entry_maker = function(bookmark)
          local display = common.format(bookmark, bookmarks)
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
          local selected = action_state.get_selected_entry().value
          callback(selected)
        end)
        return true
      end,
    })
    :find()
end

---@param cmds {name: string, callback: function}
---@param opts? {prompt?: string}
local function pick_commands(cmds, opts)
  opts = opts or {}
  local prompt = opts.prompt or "Select commands"

  pickers
    .new(opts, {
      prompt_title = prompt,
      finder = finders.new_table({
        results = cmds,
        ---@param cmd Bookmark.Command
        ---@return table
        entry_maker = function(cmd)
          return {
            value = cmd,
            display = cmd.name, -- TODO: add description
            ordinal = cmd.name,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selected = action_state.get_selected_entry().value
          selected.callback()
        end)
        return true
      end,
    })
    :find()
end

local function pick_bookmark_of_current_project(callback, opts)
  local project_name = require("bookmarks.utils").find_project_name()
  local bookmarks = repo.mark.read.find_by_project(project_name)

  pickers
    .new(opts, {
      prompt_title = "Bookmark in current project",
      finder = finders.new_table({
        results = bookmarks,
        ---@param bookmark Bookmarks.Bookmark
        entry_maker = function(bookmark)
          local display = common.format(bookmark, bookmarks)
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
          local selected = action_state.get_selected_entry().value
          callback(selected)
        end)
        return true
      end,
    })
    :find()
end

return {
  pick_bookmark_of_current_project = pick_bookmark_of_current_project,
  pick_bookmark_list = pick_bookmark_list,
  pick_bookmark = pick_bookmark,
  pick_commands = pick_commands,
}
