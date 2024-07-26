local repo = require("bookmarks.repo")
local sign = require("bookmarks.sign")
local domain = require("bookmarks.bookmark")


local M = {}

---@param name string
---@param line_no number
function M.create_folder(name, line_no)
  local ctx = vim.b._bm_context.line_contexts[line_no]

  local bookmark_lists = repo.bookmark_list.read.find_all()
  for _, bookmark_list in ipairs(bookmark_lists) do
    if domain.bookmark_list.create_tree_folder(bookmark_list, ctx.id, name) then
      repo.bookmark_list.write.save(bookmark_list)
      break
    end
  end

  sign.refresh_tree()
end


---@param line_no number
function M.cut(line_no)
  local ctx = vim.b._bm_context.line_contexts[line_no]
  vim.b._bm_tree_cut = ctx.id
  vim.print("Cut: " .. ctx.id)
end


---@param line_no number
function M.paste(line_no)
  local ctx = vim.b._bm_context.line_contexts[line_no]
  local _cut_id = vim.b._bm_tree_cut
  if not _cut_id then
    return
  end

  vim.b._bm_tree_cut = nil
  vim.print("Paste: " .. ctx.id .. " from " .. _cut_id)

  local bookmark_lists = repo.bookmark_list.read.find_all()
  for _, bookmark_list in ipairs(bookmark_lists) do
    if domain.bookmark_list.tree_paste(bookmark_list, _cut_id, ctx.id) then
      repo.bookmark_list.write.save(bookmark_list)
      break
    end
  end

  sign.refresh_tree()
end

---@param line_no number
---@return Bookmarks.Bookmark?
function M.collapse(line_no)
  local ctx = vim.b._bm_context.line_contexts[line_no]
  local bookmark_lists = repo.bookmark_list.read.find_all()
  local ret = nil
  for _, bookmark_list in ipairs(bookmark_lists) do
    local find, bookmark = domain.bookmark_list.tree_collapse(bookmark_list, ctx.id)
    if not find then
      goto continue
    end

    if bookmark then
      ret = bookmark
    else
      repo.bookmark_list.write.save(bookmark_list)
      sign.refresh_tree()
    end

    ::continue::
  end

  return ret
end

---@param line_no number
function M.delete(line_no)
  local ctx = vim.b._bm_context.line_contexts[line_no]
  local bookmark_lists = repo.bookmark_list.read.find_all()
  for _, bookmark_list in ipairs(bookmark_lists) do
    if domain.bookmark_list.tree_delete(bookmark_list, ctx.id) then
      repo.bookmark_list.write.save(bookmark_list)
      break
    end
  end

  sign.refresh_tree()
end

return M
