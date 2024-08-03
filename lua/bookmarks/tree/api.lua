local repo = require("bookmarks.repo")
local sign = require("bookmarks.sign")
local domain = require("bookmarks.domain")
local utils = require("bookmarks.utils")

---@class Bookmarks.CopyContext
---@field line_no number
---@field opr string

local M = {}

---@param name string
---@param line_no number
function M.create_folder(name, line_no)
  local ctx = vim.b._bm_context.line_contexts[line_no]

  local bookmark_list = repo.bookmark_list.read.must_find_by_name(ctx.root_name)
  if not bookmark_list then
    utils.log("No bookmark list find")
    return
  end

  domain.bookmark_list.create_folder(bookmark_list, ctx.id, name)

  repo.bookmark_list.write.save(bookmark_list)
  sign.refresh_tree()
end

---@param line_no number
function M.cut(line_no)
  vim.b._bm_tree_cut = {
    line_no = line_no,
    opr = "cut",
  }

  local _namespace = require("bookmarks.sign").namespace
  vim.api.nvim_buf_clear_namespace(0, _namespace.ns, 0, -1)
  vim.api.nvim_buf_add_highlight(0, _namespace.ns, _namespace.hl_name, line_no - 1, 0, -1)
end

---@param line_no number
function M.copy(line_no)
  vim.b._bm_tree_cut = {
    line_no = line_no,
    opr = "copy",
  }

  local _namespace = require("bookmarks.sign").namespace
  vim.api.nvim_buf_clear_namespace(0, _namespace.ns, 0, -1)
  vim.api.nvim_buf_add_highlight(0, _namespace.ns, _namespace.hl_name, line_no - 1, 0, -1)
end

---@param line_no number
function M.paste(line_no)
  ---@type Bookmarks.CopyContext
  local opr_ctx = vim.b._bm_tree_cut
  if not opr_ctx then
    utils.log("No operation")
    return
  end

  ---@type Bookmarks.LineContext
  local cut_ctx = vim.b._bm_context.line_contexts[opr_ctx.line_no]
  local bookmark_list = repo.bookmark_list.read.must_find_by_name(cut_ctx.root_name)
  if not bookmark_list then
    utils.log("No bookmark list find")
    return
  end

  local ctx = vim.b._bm_context.line_contexts[line_no]
  if domain.bookmark_list.is_descendant_by_id(bookmark_list, cut_ctx.id, ctx.id) then
    utils.log("Can't paste to descendant")
    return
  end

  local cut_node = nil
  if opr_ctx.opr == "copy" then
    cut_node = domain.bookmark_list.copy_node(bookmark_list, cut_ctx.id)
  else
    cut_node = domain.bookmark_list.remove_node(bookmark_list, cut_ctx.id)
  end

  if not cut_node then
    utils.log("No cut node")
    return
  end

  repo.bookmark_list.write.save(bookmark_list)

  local paste_bookmark_list = repo.bookmark_list.read.must_find_by_name(ctx.root_name)
  if not paste_bookmark_list then
    utils.log("No paste bookmark list")
    return
  end

  domain.bookmark_list.paste(paste_bookmark_list, ctx.id, cut_node)
  repo.bookmark_list.write.save(paste_bookmark_list)

  sign.refresh_tree()
end

---@param line_no number
---@return Bookmarks.Bookmark?
function M.collapse(line_no)
  ---@type Bookmarks.LineContext
  local ctx = vim.b._bm_context.line_contexts[line_no]
  local bookmark_list = repo.bookmark_list.read.must_find_by_name(ctx.root_name)
  if not bookmark_list then
    return
  end

  local ret = domain.bookmark_list.collapse_node(bookmark_list, ctx.id)
  if ret then
    return ret
  end

  repo.bookmark_list.write.save(bookmark_list)
  sign.refresh_tree()
end

---@param line_no number
function M.delete(line_no)
  local ctx = vim.b._bm_context.line_contexts[line_no]
  local bookmark_list = repo.bookmark_list.read.must_find_by_name(ctx.root_name)

  domain.bookmark_list.remove_node(bookmark_list, ctx.id)
  repo.bookmark_list.write.save(bookmark_list)

  sign.refresh_tree()
end

function M.open_treeview()
  require("bookmarks.tree.operate").open_treeview()
end

return M
