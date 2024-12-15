local Service = require("bookmarks.domain.service")
local Ctx = require("bookmarks.tree.ctx")
local Repo = require("bookmarks.domain.repo")
local Render = require("bookmarks.tree.render")
local Info = require("bookmarks.info")

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
    Service.set_active_list(root_node.id)
    Render.refresh(root_node)
  end
end

--- Rename a node
function M.rename()
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

  -- Get user input for new name
  vim.ui.input({ 
    prompt = "Enter new name: ",
    default = node.name
  }, function(input)
    if not input then
      return
    end

    -- Update node name
    Service.rename_node(node.id, input)

    -- Refresh the tree view
    local root = Repo.find_node(ctx.lines_ctx.root_id)
    if root then
      Render.refresh(root)
    end
  end)
end

--- goto the bookmark, open the bookmark in the previous window
function M.goto()
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

  -- Only proceed if it's a bookmark
  if node.type ~= "bookmark" then
    return
  end

  -- If previous window exists and is valid, set it as target
  if ctx.previous_window and vim.api.nvim_win_is_valid(ctx.previous_window) then
    vim.api.nvim_set_current_win(ctx.previous_window)
  end

  -- Go to bookmark in current window (which is now the previous window)
  Service.goto_bookmark(node.id)
end

--- Cut the current bookmark
function M.cut()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]
  local ctx = Ctx.get_ctx()

  -- Get line context for the current line
  local line_ctx = ctx.lines_ctx.lines_ctx[line_no]
  if not line_ctx then
    return
  end

  -- Do nothing if root node
  if line_ctx.id == 0 then
    return
  end

  -- Find the node
  local node = Repo.find_node(line_ctx.id)
  if not node then
    return
  end

  -- Store the node with operation type
  Ctx.set_store(node, "cut")
  vim.notify(string.format("Cut node: %s", node.name), vim.log.levels.INFO)

  -- Delete the node from current position
  Service.delete_node(node.id)

  -- Refresh the tree view
  local root = Repo.find_node(ctx.lines_ctx.root_id)
  if root then
    Render.refresh(root)
  end
end

--- Copy the current node
function M.copy()
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

  -- Store the node with operation type
  Ctx.set_store(node, "copy")
  vim.notify(string.format("Copied node: %s", node.name), vim.log.levels.INFO)
end

--- Paste the cut/copied node, a new node instance will be created
function M.paste()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]
  local ctx = Ctx.get_ctx()

  -- Check if we have something stored
  if not ctx.store or not ctx.store.node or not ctx.store.operation then
    vim.notify("No node to paste", vim.log.levels.WARN)
    return
  end

  -- Get line context for the target position
  local line_ctx = ctx.lines_ctx.lines_ctx[line_no]
  if not line_ctx then
    return
  end

  -- Get target node and determine parent_id and position
  local target_node = Repo.find_node(line_ctx.id)
  if not target_node then
    return
  end

  local parent_id, position
  if target_node.type == "list" then
    -- If target is a list, paste at the end of that list
    parent_id = target_node.id
    -- Get children count for the target list
    local children = target_node.children or {}
    position = #children  -- Put at the end of the list
  else
    -- If target is not a list, paste at target's position in parent list
    parent_id = Repo.get_parent_id(target_node.id)
    if not parent_id then
      vim.notify("Invalid paste target", vim.log.levels.ERROR)
      return
    end
    position = target_node.order
  end

  if position == nil then
    vim.notify("invalid position", vim.log.levels.ERROR)
    return
  end

  -- Paste the node
  Service.paste_node(ctx.store.node, parent_id, position)

  -- Clear store if this was a cut operation
  if ctx.store.operation == "cut" then
    ctx.store = nil
  end

  -- Refresh the tree view
  local root = Repo.find_node(ctx.lines_ctx.root_id)
  if root then
    require("bookmarks.tree.render").refresh(root)
  end
end

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

--- Delete current node
function M.delete()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]
  local ctx = Ctx.get_ctx()

  -- Get line context for the current line
  local line_ctx = ctx.lines_ctx.lines_ctx[line_no]
  if not line_ctx then
    return
  end

  -- Do nothing if root node
  if line_ctx.id == 0 then
    return
  end

  -- Find the node
  local node = Repo.find_node(line_ctx.id)
  if not node then
    return
  end

  -- Delete the node
  Service.delete_node(node.id)

  -- Refresh the tree view
  local root = Repo.find_node(ctx.lines_ctx.root_id)
  if root then
    Render.refresh(root)
  end
end

function M.quit()
  local ctx = Ctx.get_ctx()
  vim.api.nvim_win_close(ctx.win, true)
  Ctx.clear()
end

--- Move current node up
function M.move_up()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]
  local ctx = Ctx.get_ctx()

  -- Get line context for the current line
  local line_ctx = ctx.lines_ctx.lines_ctx[line_no]
  if not line_ctx then
    return
  end

  -- Get current node
  local current_node = Repo.find_node(line_ctx.id)
  if not current_node then
    return
  end

  -- Get previous line context
  local prev_line_ctx = ctx.lines_ctx.lines_ctx[line_no - 1]
  if not prev_line_ctx then
    return -- Already at top
  end

  -- Get previous node
  local prev_node = Repo.find_node(prev_line_ctx.id)
  if not prev_node then
    return
  end

  -- Switch positions
  Service.switch_position(current_node, prev_node)

  -- Refresh the tree view
  local root = Repo.find_node(ctx.lines_ctx.root_id)
  if root then
    require("bookmarks.tree.render").refresh(root)
  end

  -- Move cursor up
  vim.api.nvim_win_set_cursor(0, { line_no - 1, 0 })
end

function M.move_down()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]
  local ctx = Ctx.get_ctx()

  -- Get line context for the current line
  local line_ctx = ctx.lines_ctx.lines_ctx[line_no]
  if not line_ctx then
    return
  end

  -- Get current node
  local current_node = Repo.find_node(line_ctx.id)
  if not current_node then
    return
  end

  -- Get next line context
  local next_line_ctx = ctx.lines_ctx.lines_ctx[line_no + 1]
  if not next_line_ctx then
    return -- Already at bottom
  end

  -- Get next node
  local next_node = Repo.find_node(next_line_ctx.id)
  if not next_node then
    return
  end

  -- Switch positions
  Service.switch_position(current_node, next_node)

  -- Refresh the tree view
  local root = Repo.find_node(ctx.lines_ctx.root_id)
  if root then
    require("bookmarks.tree.render").refresh(root)
  end

  -- Move cursor down
  vim.api.nvim_win_set_cursor(0, { line_no + 1, 0 })
end

function M.set_active()
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

  -- If it's a bookmark, get its parent list
  local list_node
  if node.type ~= "list" then
    local parent_id = Repo.get_parent_id(node.id)
    if not parent_id then
      return
    end
    list_node = Repo.find_node(parent_id)
  else
    list_node = node
  end

  -- Set the active list
  if list_node then
    Service.set_active_list(list_node.id)
    -- Refresh tree view to update UI
    local root = Repo.find_node(ctx.lines_ctx.root_id)
    if root then
      Render.refresh(root)
    end
  end
end

---Refresh tree view
function M.refresh()
  local ctx = Ctx.get_ctx().lines_ctx
  local root = Repo.find_node(ctx.root_id)
  if not root then
    error(string.format("Failed to find root node with id: %d", ctx.root_id))
  end
  Render.refresh(root)
end

function M.show_info()
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

  Info.show_bookmark_info(node)
end

--- reverse display order
function M.reverse()
  local ctx = Ctx.get_ctx()
  
  -- Toggle sort order
  ctx.sort_ascending = not (ctx.sort_ascending or false)
  vim.g.bookmark_tree_view_ctx = ctx
  
  -- Refresh the view
  local root = Repo.find_node(ctx.lines_ctx.root_id)
  if root then
    Render.refresh(root)
  end
  
  -- Notify user of sort order change
  local order = ctx.sort_ascending and "ascending" or "descending"
  vim.notify("Sort order: " .. order, vim.log.levels.INFO)
end

return M
