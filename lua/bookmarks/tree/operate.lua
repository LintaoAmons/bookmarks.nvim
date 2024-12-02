local Service = require("bookmarks.domain.service")
local Ctx = require("bookmarks.tree.ctx")
local Repo = require("bookmarks.domain.repo")
local Render = require("bookmarks.tree.render")

local M = {}

function M.create_list()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]
  local ctx = Ctx.get_ctx().lines_ctx

  -- Get line context for the current line
  local line_ctx = ctx.lines_ctx[line_no]
  if not line_ctx then
    error("Invalid cursor position: no line context found")
  end

  -- Find the current node
  local current_node = Repo.find_node(line_ctx.id)
  if not current_node then
    error(string.format("Failed to find node with id: %d", line_ctx.id))
  end

  -- Get parent node
  local parent_id = Repo.get_parent_id(current_node.id)

  if not parent_id then
    error(string.format("Failed to get parent id of %s", current_node.id))
  end

  -- Get user input for new list name
  vim.ui.input({ prompt = "Enter list name: " }, function(input)
    if not input then
      return
    end

    -- Create new list and handle potential errors
    Service.create_list(input, parent_id)

    -- Refresh tree view
    local root = Repo.find_node(ctx.root_id)
    if not root then
      error(string.format("Failed to find root node with id: %d", ctx.root_id))
    end

    Render.refresh(root)
  end)
end

---Go one level up
function M.level_up()
  local ctx = Ctx.get_ctx().lines_ctx

  -- If at top level, do nothing
  if ctx.root_id == 0 then
    return
  end

  -- Get current root node
  local current_root = Repo.find_node(ctx.root_id)
  if not current_root then
    error(string.format("Failed to find root node with id: %d", ctx.root_id))
  end

  -- Get parent node id
  local parent_id = Repo.get_parent_id(current_root.id)
  if not parent_id then
    return
  end

  -- Get parent node and refresh view
  local parent_node = Repo.find_node(parent_id)
  if parent_node then
    Render.refresh(parent_node)
  end
end

--- Set root node
function M.set_root()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]
  local ctx = Ctx.get_ctx()

  -- Get line context for the current line
  local line_ctx = ctx.lines_ctx.lines_ctx[line_no]
  if not line_ctx then
    return
  end

  -- Find the node
  local node = Repo.find_node(line_ctx.id)
  if not node then
    return
  end

  -- If it's a bookmark, get its parent node
  local root_node
  if node.type ~= "list" then
    local parent_id = Repo.get_parent_id(node.id)
    if not parent_id then
      return
    end
    root_node = Repo.find_node(parent_id)
  else
    root_node = node
  end

  -- Refresh tree view with new root
  if root_node then
    Render.refresh(root_node)
  end
end

-- function M.tree_cut()
--   local line_no = vim.api.nvim_win_get_cursor(0)[1]
--   Api.cut(line_no)
-- end
--
-- function M.copy()
--   local line_no = vim.api.nvim_win_get_cursor(0)[1]
--   Api.copy(line_no)
-- end
--
-- function M.tree_paste()
--   local line_no = vim.api.nvim_win_get_cursor(0)[1]
--   Api.paste(line_no)
-- end

function M.toggle()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]
  local ctx = Ctx.get_ctx()

  -- Get line context for the current line
  local line_ctx = ctx.lines_ctx.lines_ctx[line_no]
  if not line_ctx then
    return
  end

  -- Find the node
  local node = Repo.find_node(line_ctx.id)
  if not node then
    return
  end

  if node.type == "list" then
    -- Toggle list expanded state
    Repo.toggle_list_expanded(node.id)
    -- Refresh tree view
    local root = Repo.find_node(line_ctx.root_id)
    if root then
      require("bookmarks.tree.render").refresh(root)
    end
  else
    -- Store current window before going to bookmark
    local current_window = vim.api.nvim_get_current_win()

    -- If previous window exists and is valid, set it as target
    if ctx.previous_window and vim.api.nvim_win_is_valid(ctx.previous_window) then
      vim.api.nvim_set_current_win(ctx.previous_window)
    end

    -- Go to bookmark in current window (which is now the previous window)
    Service.goto_bookmark(node.id)

    -- Return to tree window
    vim.api.nvim_set_current_win(current_window)
  end
end

-- function M.delete()
--   local line_no = vim.api.nvim_win_get_cursor(0)[1]
--   vim.ui.input({ prompt = "You really want to delete the bookmark? y/N" }, function(input)
--     if input == "y" then
--       Api.delete(line_no)
--     end
--   end)
-- end
--

function M.quit()
  local ctx = Ctx.get_ctx()
  vim.api.nvim_win_close(ctx.win, true)
  Ctx.clear()
end

function M.active()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]
  local ctx = vim.b._bm_context.line_contexts[line_no]
  api.set_active_list(ctx.root_name)
  -- sign.refresh_tree()
end

---Refresh tree view
function M.refresh()
  local ctx = Ctx.get_ctx().lines_ctx
  local root = Repo.find_node(ctx.root_id)
  if not root then
    error(string.format("Failed to find root node with id: %d", ctx.root_id))
  end
  require("bookmarks.tree.render").refresh(root)
end

return M
