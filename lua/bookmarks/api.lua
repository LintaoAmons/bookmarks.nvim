local Service = require("bookmarks.domain.service")
local Sign = require("bookmarks.sign")
local Tree = require("bookmarks.tree.operate")

local M = {}

local refresh = function()
  Sign.safe_refresh_signs()
  pcall(Tree.refresh)
end

--- Marks the current location into a special list.
--- e.g. :lua require("bookmarks.api").mark_the_location_into_a_spetial_list("My LSP Jumps")
---@param special_list_name string The name of the special list to use or create. Defaults to "LSP Jumps".
function M.mark_the_location_into_a_spetial_list(special_list_name)
  local _, new_bookmark_id = Service.mark_the_location_into_a_spetial_list(special_list_name)

  if new_bookmark_id then
    refresh()
  end
end

--- Mark a file by creating a bookmark for it
--- @param filepath string # the file path to mark
--- @param parent_list_id number? # optional, parent list ID, if not present, then use current active_list id
--- @return Bookmarks.Node # Returns the created bookmark
function M.markfile(filepath, parent_list_id)
  local created = Service.markfile(filepath, parent_list_id)

  if created then
    refresh()
  end
end

return M
