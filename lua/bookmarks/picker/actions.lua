local M = {}
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local Service = require("bookmarks.domain.service")

-- Helper function to get selected bookmark
local function get_selected_bookmark()
  local selection = action_state.get_selected_entry()
  if not selection then
    return nil
  end
  return selection.value
end

-- Go to bookmark location
function M.goto_bookmark(prompt_bufnr)
  local bookmark = get_selected_bookmark()
  if not bookmark then
    return
  end

  actions.close(prompt_bufnr)
  Service.goto_bookmark(bookmark.id)
end

-- Open bookmark in new tab
function M.open_in_new_tab(prompt_bufnr)
  local bookmark = get_selected_bookmark()
  if not bookmark then
    return
  end

  actions.close(prompt_bufnr)
  Service.goto_bookmark(bookmark.id, { cmd = "tabnew" })
end

-- Open bookmark in vertical split
function M.open_in_vsplit(prompt_bufnr)
  local bookmark = get_selected_bookmark()
  if not bookmark then
    return
  end

  actions.close(prompt_bufnr)
  Service.goto_bookmark(bookmark.id, { cmd = "vsplit" })
end

-- Open bookmark in horizontal split
function M.open_in_split(prompt_bufnr)
  local bookmark = get_selected_bookmark()
  if not bookmark then
    return
  end

  actions.close(prompt_bufnr)
  Service.goto_bookmark(bookmark.id, { cmd = "split" })
end

-- Delete bookmark
function M.delete(prompt_bufnr)
  local bookmark = get_selected_bookmark()
  if not bookmark then
    return
  end

  Service.delete_node(bookmark.id)
  actions.close(prompt_bufnr)
end

return M
