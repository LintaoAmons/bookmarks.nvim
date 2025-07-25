local Node = require("bookmarks.domain.node")
local Location = require("bookmarks.domain.location")
local Repo = require("bookmarks.domain.repo")
-- TODO: remove this dependency, fire domain events instead
local Sign = require("bookmarks.sign")

local M = {}

--- Create a new bookmark
---@param bookmark Bookmarks.NewNode # the bookmark
---@param parent_list_id number? # parent list ID, if nil, bookmark will be added to current active list
---@return Bookmarks.Node # Returns the created bookmark
function M.new_bookmark(bookmark, parent_list_id)
  if bookmark.type ~= "bookmark" then
    error("Node is not a bookmark")
  end
  parent_list_id = parent_list_id or Repo.ensure_and_get_active_list().id

  local id = Repo.insert_node(bookmark, parent_list_id)

  return Repo.find_node(id) or error("Failed to create bookmark")
end

--- Create a new bookmark
--- e.g.
--- :lua require("bookmarks.domain.service").mark("mark current line")
---@param name string # the name of the bookmark
---@param location Bookmarks.Location? # location of the bookmark
---@param parent_list_id number? # parent list ID, if nil, bookmark will be added to current active list
---@return Bookmarks.Node # Returns the created bookmark
function M.toggle_mark(name, location, parent_list_id)
  location = location or Location.get_current_location()

  -- if location have already bookmark, and name is empty string, remove it
  local existing_bookmark = Repo.find_bookmark_by_location(location)
  if existing_bookmark then
    if name == "" then
      M.remove_bookmark(existing_bookmark.id)
      return existing_bookmark
    else
      return M.rename_node(existing_bookmark.id, name)
    end
  end

  -- else create a new bookmark
  parent_list_id = parent_list_id or Repo.ensure_and_get_active_list().id
  local bookmark = Node.new_bookmark(name)

  local id = Repo.insert_node(bookmark, parent_list_id)

  return Repo.find_node(id) or error("Failed to create bookmark")
end

--- Remove a bookmark
---@param bookmark_id number # bookmark ID
function M.remove_bookmark(bookmark_id)
  Repo.delete_node(bookmark_id)
end

--- Find an existing bookmark under the cursor
---@param location Bookmarks.Location?
---@return Bookmarks.Node? # Returns the bookmark, or nil if not found
function M.find_bookmark_by_location(location)
  location = location or Location.get_current_location()
  return Repo.find_bookmark_by_location(location)
end

--- Find bookmarks of current file
--- @param filepath  string
--- @return Bookmarks.Node[]
function M.find_bookmarks_of_file(filepath)
  local filepath = filepath or Location.get_current_location().path
  local bookmarks = Repo.get_all_bookmarks()
  local file_bms = {}

  for _, bookmark in ipairs(bookmarks) do
    if filepath == bookmark.location.path then
      table.insert(file_bms, bookmark)
    end
  end

  return file_bms
end

--- Create a new list and set it as active
---@param name string # the name of the list
---@param parent_list_id number? # parent list ID, if nil, list will be added to root list
---@return Bookmarks.Node # Returns the created list
function M.create_list(name, parent_list_id)
  -- If no parent_list_id provided, use root list (id = 0)
  parent_list_id = parent_list_id or 0

  local list = Node.new_list(name)
  local id = Repo.insert_node(list, parent_list_id)

  M.set_active_list(id)
  local created = Repo.find_node(id) or error("Failed to create list")
  Sign.safe_refresh_signs()
  -- return to normal mode
  vim.cmd("stopinsert") -- TODO: remove this line and figure out why it's ends in insert mode

  return created
end

--- rename a bookmark or list
---@param node_id number # bookmark or list ID
---@param new_name string # new name
---@return Bookmarks.Node
function M.rename_node(node_id, new_name)
  local node = Repo.find_node(node_id)
  if not node then
    error("Node not found")
  end

  node.name = new_name
  return Repo.update_node(node)
end

--- goto bookmark's location
---@param bookmark_id number # bookmark ID
---@param opts? {cmd?: "e" | "tabnew" | "split" | "vsplit" | "float", keep_cursor?: boolean}
---@return integer? float_win_id if a float window was created/managed, otherwise nil
function M.goto_bookmark(bookmark_id, opts)
  opts = opts or {}
  local float_win_id_to_return = nil

  local original_win = vim.api.nvim_get_current_win()
  local original_cursor = vim.api.nvim_win_get_cursor(original_win)

  local node = Repo.find_node(bookmark_id)
  if not node then
    error("Bookmark not found")
  end

  if node.type ~= "bookmark" then
    error("Node is not a bookmark")
  end

  if not node.location then
    error("Bookmark has no location")
  end

  -- Update visited timestamp
  node.visited_at = os.time()
  Repo.update_node(node)

  -- Handle floating window case
  local cmd = opts.cmd or "edit"
  if opts.cmd == "float" then
    local buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

    -- Calculate window size and position
    local width = math.min(160, vim.o.columns - 4)
    local height = math.min(40, vim.o.lines - 4)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = width,
      height = height,
      row = row,
      col = col,
      style = "minimal",
      border = "rounded",
    })
    float_win_id_to_return = win

    -- Load the file content
    vim.cmd("edit " .. vim.fn.fnameescape(node.location.path))
  else
    if node.location.path ~= vim.fn.expand("%:p") then
      vim.cmd(cmd .. " " .. vim.fn.fnameescape(node.location.path))
    end
  end

  -- Move cursor to the bookmarked position
  vim.api.nvim_win_set_cursor(0, { node.location.line, node.location.col })
  vim.cmd("normal! zz")
  Sign.safe_refresh_signs()

  if opts.keep_cursor then
    vim.api.nvim_set_current_win(original_win)
    vim.api.nvim_win_set_cursor(original_win, original_cursor)
  end
  return float_win_id_to_return
end

local FindDirection = { FORWARD = 0, BACKWARD = 1 }

--- finds the bookmark in a given direction by 'order id' within a BookmarkList
---@param callback fun(bookmark: Bookmarks.Node): nil
---@param bookmark_list Bookmarks.Node
---@param direction number
---@param fail_msg string
local function find_bookmark_in_id_order(callback, bookmark_list, direction, fail_msg)
  local bookmarks = Node.get_all_bookmarks(bookmark_list)
  local cur_lnr = vim.api.nvim_win_get_cursor(0)[1]

  if #bookmarks == 0 then
    vim.notify("No bookmarks available in this BookmarkList", vim.log.levels.WARN)
    return
  end

  -- sort in ascending by order id
  table.sort(bookmarks, function(lhs, rhs)
    return lhs.order < rhs.order
  end)

  -- find last visited bookmark in list
  local bm_idx
  local running_max = 0
  for i, bookmark in ipairs(bookmarks) do
    if bookmark.visited_at > running_max then
      bm_idx = i
      running_max = bookmark.visited_at
    elseif bookmark.visited_at == running_max and bookmark.location.line == cur_lnr then
      -- if at least two bookmarks have same visited time, goto is being performed
      -- too fast for time tracking to keep up
      -- default to bookmark under cursor as last visited
      bm_idx = i
      break
    end
  end

  local selected_bm
  -- circular traverse
  if direction == FindDirection.FORWARD then
    selected_bm = bookmarks[(bm_idx - 1 + 1) % #bookmarks + 1]
  elseif direction == FindDirection.BACKWARD then
    selected_bm = bookmarks[(bm_idx - 1 - 1) % #bookmarks + 1]
  else
    error("Invalid direction, not a valid call to this function")
  end

  if selected_bm then
    callback(selected_bm)
  else
    vim.notify(fail_msg, vim.log.levels.WARN)
  end
end

--- finds the bookmark in a given direction in 'line order' within a BookmarkList
---@param callback fun(bookmark: Bookmarks.Node): nil
---@param bookmark_list Bookmarks.Node
---@param direction number
---@param fail_msg string
local function find_closest_bookmark_in_line_order(callback, bookmark_list, direction, fail_msg)
  local enable_wraparound = vim.g.bookmarks_config.navigation.next_prev_wraparound_same_file
  local bookmarks = Node.get_all_bookmarks(bookmark_list)
  local filepath = vim.fn.expand("%:p")
  local cur_lnr = vim.api.nvim_win_get_cursor(0)[1]
  local file_bms = {}

  for _, bookmark in ipairs(bookmarks) do
    if filepath == bookmark.location.path then
      table.insert(file_bms, bookmark)
    end
  end

  if #file_bms == 0 then
    vim.notify("No bookmarks available in this file", vim.log.levels.WARN)
    return
  end

  -- sort in ascending line number order
  table.sort(file_bms, function(lhs, rhs)
    return lhs.location.line < rhs.location.line
  end)
  local min_bm = file_bms[1]
  local max_bm = file_bms[#file_bms]

  local selected_bm
  if direction == FindDirection.FORWARD then
    if enable_wraparound and cur_lnr >= max_bm.location.line then
      selected_bm = min_bm
    else
      for _, bookmark in ipairs(file_bms) do
        if bookmark.location.line > cur_lnr then
          selected_bm = bookmark
          break
        end
      end
    end
  elseif direction == FindDirection.BACKWARD then
    if enable_wraparound and cur_lnr <= min_bm.location.line then
      selected_bm = max_bm
    else
      for i = #file_bms, 1, -1 do
        local bookmark = file_bms[i]
        if bookmark.location.line < cur_lnr then
          selected_bm = bookmark
          break
        end
      end
    end
  else
    error("Invalid direction, not a valid call to this function")
  end

  if selected_bm then
    callback(selected_bm)
  else
    vim.notify(fail_msg, vim.log.levels.WARN)
  end
end

--- finds the next bookmark in line number order within the current active BookmarkList
---@param callback fun(bookmark: Bookmarks.Node): nil
function M.find_next_bookmark_line_order(callback)
  find_closest_bookmark_in_line_order(
    callback,
    Repo.ensure_and_get_active_list(),
    FindDirection.FORWARD,
    "No next bookmark found within the active BookmarkList in this file"
  )
end

--- finds the previous bookmark in line number order within the current active BookmarkList
---@param callback fun(bookmark: Bookmarks.Node): nil
function M.find_prev_bookmark_line_order(callback)
  find_closest_bookmark_in_line_order(
    callback,
    Repo.ensure_and_get_active_list(),
    FindDirection.BACKWARD,
    "No previous bookmark found within the active BookmarkList in this file"
  )
end

--- finds the next bookmark by order id within the current active BookmarkList
---@param callback fun(bookmark: Bookmarks.Node): nil
function M.find_next_bookmark_id_order(callback)
  find_bookmark_in_id_order(
    callback,
    Repo.ensure_and_get_active_list(),
    FindDirection.FORWARD,
    "No next bookmark found within the active BookmarkList"
  )
end

--- finds the previous bookmark by order id within the current active BookmarkList
---@param callback fun(bookmark: Bookmarks.Node): nil
function M.find_prev_bookmark_id_order(callback)
  find_bookmark_in_id_order(
    callback,
    Repo.ensure_and_get_active_list(),
    FindDirection.BACKWARD,
    "No previous bookmark found within the active BookmarkList"
  )
end

--- get all bookmarks of the active list
---@return Bookmarks.Node[]
function M.get_all_bookmarks_of_active_list()
  local active_list = Repo.ensure_and_get_active_list()
  return Node.get_all_bookmarks(active_list)
end

--- find a bookmark or list by ID
---@param node_id number # bookmark or list ID
---@return Bookmarks.Node? # Returns the bookmark or list, or nil if not found
function M.find_node(node_id) end

--- add a bookmark or list to a list
---@param node_id number
---@param parent_list_id number
function M.add_to_list(node_id, parent_list_id) end

--- copy a bookmark to a list
---@param bookmark_id number # bookmark ID
---@param list_id number # list ID
function M.copy_bookmark_to_list(bookmark_id, list_id) end

--- move a bookmark to a list
---@param bookmark_id number # bookmark ID
---@param list_id number # list ID
function M.move_bookmark_to_list(bookmark_id, list_id) end

--- delete a bookmark or list
---@param id number # bookmark or list ID
function M.delete_node(id)
  -- Check if node exists
  local node = Repo.find_node(id)
  if not node then
    error("Node not found")
  end

  -- Don't allow deleting root node
  if id == 0 then
    error("Cannot delete root node")
  end

  -- Delete the node and all its relationships
  Repo.delete_node(id)
end

--- Remove the node from its current list
--- @param node_id number # node ID
--- @param parent_id number # Parent node id
function M.remove_from_list(node_id, parent_id)
  Repo.remove_from_list(node_id, parent_id)
end

--- Export list as text to a buffer. useful when you want to provide context to AI
--- @param list_id number # list ID
function M.export_list_to_buffer(list_id) end

--- Set the active list
--- @param list_id number # list ID
function M.set_active_list(list_id)
  Repo.set_active_list(list_id)
end

--- Switch position of two bookmarks in the same list
--- @param b1 Bookmarks.Node
--- @param b2 Bookmarks.Node
function M.switch_position(b1, b2)
  -- Get parent IDs for both nodes
  local parent_id1 = Repo.get_parent_id(b1.id)
  local parent_id2 = Repo.get_parent_id(b2.id)

  -- Check if nodes are in the same list
  if parent_id1 ~= parent_id2 then
    error("Cannot switch positions of nodes from different lists")
  end

  -- Switch their order values
  local temp_order = b1.order
  b1.order = b2.order
  b2.order = temp_order

  -- Update both nodes in the repository
  Repo.update_node(b1)
  Repo.update_node(b2)
end

---Link a bookmark to another bookmark
---@param bookmark_id number
---@param target_bookmark_id number
---@return boolean
function M.link_bookmarks(bookmark_id, target_bookmark_id)
  local bookmark = Repo.find_node(bookmark_id)
  local target = Repo.find_node(target_bookmark_id)
  if not bookmark or not target then
    vim.notify("One or both bookmarks not found", vim.log.levels.ERROR)
    return false
  end
  if bookmark.type ~= "bookmark" or target.type ~= "bookmark" then
    vim.notify("Only bookmarks can be linked", vim.log.levels.ERROR)
    return false
  end
  Repo.link_bookmarks(bookmark_id, target_bookmark_id)
  vim.notify("Bookmarks linked successfully", vim.log.levels.INFO)
  return true
end

---Unlink a bookmark from another bookmark
---@param bookmark_id number
---@param target_bookmark_id number
---@return boolean
function M.unlink_bookmarks(bookmark_id, target_bookmark_id)
  local bookmark = Repo.find_node(bookmark_id)
  local target = Repo.find_node(target_bookmark_id)
  if not bookmark or not target then
    vim.notify("One or both bookmarks not found", vim.log.levels.ERROR)
    return false
  end
  Repo.unlink_bookmarks(bookmark_id, target_bookmark_id)
  vim.notify("Bookmarks unlinked successfully", vim.log.levels.INFO)
  return true
end

---Get linked bookmarks for a given bookmark (outgoing links)
---@param bookmark_id number
---@return Bookmarks.Node[]
function M.get_linked_out_bookmarks(bookmark_id)
  local linked_ids = Repo.get_linked_out_bookmarks(bookmark_id)
  local linked_bookmarks = {}
  for _, id in ipairs(linked_ids) do
    local bookmark = Repo.find_node(id)
    if bookmark then
      table.insert(linked_bookmarks, bookmark)
    end
  end
  return linked_bookmarks
end

---Get bookmarks that link to the given bookmark (incoming links)
---@param bookmark_id number
---@return Bookmarks.Node[]
function M.get_linked_in_bookmarks(bookmark_id)
  local linking_ids = Repo.get_linked_in_bookmarks(bookmark_id)
  local linking_bookmarks = {}
  for _, id in ipairs(linking_ids) do
    local bookmark = Repo.find_node(id)
    if bookmark then
      table.insert(linking_bookmarks, bookmark)
    end
  end
  return linking_bookmarks
end

---Paste a node at a specific position
---@param node Bookmarks.Node The node to paste
---@param parent_id number The parent list ID
---@param position number The position to paste at
---@param operation "cut"|"copy" The operation to perform
---@return Bookmarks.Node # Returns the pasted node
function M.paste_node(node, parent_id, position, operation)
  if node.type == "list" and parent_id == node.id then
    error("Cannot paste a list into itself")
  end

  if operation == "cut" then
    -- Update orders of existing nodes in target list
    local children = Repo.find_node(parent_id).children
    for _, child in ipairs(children) do
      if child.order >= position then
        child.order = child.order + 1
        Repo.update_node(child)
      end
    end

    -- Add relationship to new parent
    Repo.add_to_list(node.id, parent_id)

    -- Update node's order
    node.order = position
    return Repo.update_node(node)
  end

  -- Convert node to newNode format
  local newNode = {
    type = node.type,
    name = node.name,
    description = node.description,
    content = node.content,
    githash = node.githash,
    created_at = os.time(), -- New timestamp for the copy
    visited_at = os.time(),
    is_expanded = node.is_expanded,
    order = node.order,
  }

  -- Copy location if it exists
  if node.location then
    newNode.location = {
      path = node.location.path,
      line = node.location.line,
      col = node.location.col,
    }
  end

  local id = Repo.insert_node_at_position(newNode, parent_id, position)
  return Repo.find_node(id) or error("Failed to paste node")
end

--- Mark a file by creating a bookmark for it
--- @param filepath string # the file path to mark
--- @param parent_list_id number? # optional, parent list ID, if not present, then use current active_list id
--- @return Bookmarks.Node # Returns the created bookmark
function M.markfile(filepath, parent_list_id)
  local location = {
    path = filepath,
    line = 1,
    col = 0,
  }
  local name = Location.get_file_name(location)
  local bookmark = {
    type = "bookmark",
    name = name,
    description = "",
    content = "",
    location = location,
    created_at = os.time(),
    visited_at = os.time(),
    children = {},
    order = 0,
  }
  parent_list_id = parent_list_id or Repo.ensure_and_get_active_list().id

  local id = Repo.insert_node(bookmark, parent_list_id)
  return Repo.find_node(id) or error("Failed to create bookmark")
end

--- Use Snacks file picker to select multiple files and mark them
function M.mark_selected_files()
  -- Create a new list for the selected files
  local new_list = M.create_list("Selected Files")

  -- Set the new list as the current active list
  M.set_active_list(new_list.id)

  Snacks.picker({
    source = "files",
    confirm = function(picker)
      local selected_files = picker:selected()
      for _, item in ipairs(selected_files) do
        M.markfile(item.file, new_list.id)
      end
      picker:close()
    end,
  })
end

--- Marks the current location into a special list.
---@param special_list_name string The name of the special list to use or create.
function M.mark_the_location_into_a_spetial_list(special_list_name)
  local special_list_id

  -- Try to find the special list
  local lists = Repo.find_lists()
  for _, list_node in ipairs(lists) do
    if list_node.name == special_list_name then
      special_list_id = list_node.id
      break
    end
  end

  -- If not found, create it under the root (ID 0)
  if not special_list_id then
    local new_list_data = Node.new_list(special_list_name)
    special_list_id = Repo.insert_node(new_list_data, 0) -- 0 is the root list ID
    if not special_list_id then
      vim.notify("Failed to create special list: " .. special_list_name, vim.log.levels.ERROR)
      return
    end
  end

  local current_loc = Location.get_current_location()
  if not current_loc.path or current_loc.path == "" then
    vim.notify("Cannot mark location: current buffer has no name.", vim.log.levels.WARN)
    return
  end

  local bookmark_name = string.format("%s:%d", Location.get_file_name(current_loc), current_loc.line)
  local new_bookmark_data = Node.new_bookmark(bookmark_name, current_loc)

  local new_bookmark_id = Repo.insert_node(new_bookmark_data, special_list_id)

  if new_bookmark_id then
    vim.notify(string.format("Marked location to '%s' list: %s", special_list_name, bookmark_name), vim.log.levels.INFO)
    return special_list_id, new_bookmark_id
  else
    vim.notify("Failed to mark location to special list.", vim.log.levels.ERROR)
    return nil, nil
  end
end

return M
