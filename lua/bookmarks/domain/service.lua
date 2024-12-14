local Node = require("bookmarks.domain.node")
local Location = require("bookmarks.domain.location")
local Sign = require("bookmarks.sign")
local Repo = require("bookmarks.domain.repo")

local M = {}

--- Create a new bookmark
---@param bookmark Bookmarks.NewNode # the bookmark
---@param parent_list_id number? # parent list ID, if nil, bookmark will be added to current active list
---@return Bookmarks.Node # Returns the created bookmark
function M.new_bookmark(bookmark, parent_list_id)
  if bookmark.type ~= "bookmark" then
    error("Node is not a bookmark")
  end
  parent_list_id = parent_list_id or Repo.get_active_list().id

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
  parent_list_id = parent_list_id or Repo.get_active_list().id
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

--- Create a new list and set it as active
---@param name string # the name of the list
---@param parent_list_id number? # parent list ID, if nil, list will be added to root list
---@param location Bookmarks.Location? # mark the location when creating the list
---@return Bookmarks.Node # Returns the created list
function M.create_list(name, parent_list_id, location)
  -- If no parent_list_id provided, use root list (id = 0)
  parent_list_id = parent_list_id or 0

  local list = Node.new_list(name)
  local id = Repo.insert_node(list, parent_list_id)

  M.set_active_list(id)
  local new_bookmark = Node.new_bookmark("", location)
  M.new_bookmark(new_bookmark, id)
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
---@param opts? {cmd?: "e" | "tabnew" | "split" | "vsplit"}
function M.goto_bookmark(bookmark_id, opts)
  opts = opts or {}

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

  -- Open the file if it's not the current buffer
  local cmd = opts.cmd or "edit"
  if node.location.path ~= vim.fn.expand("%:p") then
    vim.cmd(cmd .. vim.fn.fnameescape(node.location.path))
  end

  -- Move cursor to the bookmarked position
  vim.api.nvim_win_set_cursor(0, { node.location.line, node.location.col })
  Sign.safe_refresh_signs()
end

--- get all bookmarks of the active list
---@return Bookmarks.Node[]
function M.get_all_bookmarks_of_active_list()
  local active_list = Repo.get_active_list()
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

---Paste a node at a specific position
---@param node Bookmarks.Node The node to paste
---@param parent_id number The parent list ID
---@param position number The position to paste at
---@return Bookmarks.Node # Returns the pasted node
function M.paste_node(node, parent_id, position)
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

return M
