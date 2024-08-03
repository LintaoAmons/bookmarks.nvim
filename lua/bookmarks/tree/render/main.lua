local render_context = require("bookmarks.tree.render.context")
local tree_operate = require("bookmarks.tree.operate")
local config = require("bookmarks.config")

local M = {}

---@class Bookmarks.PopupWindowCtx
---@field buf integer
---@field win integer
---@field previous_window integer

---@param opts {buf: integer,width: integer}
---@return integer
local function create_vsplit_with_width(opts)
  vim.cmd("vsplit")

  local new_win = vim.api.nvim_get_current_win()

  vim.api.nvim_win_set_width(new_win, opts.width)
  vim.api.nvim_win_set_buf(new_win, opts.buf)

  return new_win
end

---@param popup_content string[]
---@return Bookmarks.PopupWindowCtx
local function menu_popup_window(popup_content)
  local previous_window = vim.api.nvim_get_current_win()
  local popup_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, popup_content)
  vim.api.nvim_buf_set_option(popup_buf, "modifiable", false)

  local win = create_vsplit_with_width({ buf = popup_buf, width = 30 })

  return {
    buf = popup_buf,
    win = win,
    previous_window = previous_window,
  }
end

local function register_local_shortcuts(buf)
  local keymap = config.default_config.treeview.keymap
  if vim.g.bookmarks_config.treeview and vim.g.bookmarks_config.treeview.keymap then
    keymap = vim.g.bookmarks_config.treeview.keymap
  end

  local options = {
    noremap = true,
    silent = true,
    nowait = true,
    buffer = buf,
  }

  for action, keys in pairs(keymap) do
    if type(keys) == "string" then
      pcall(vim.keymap.set, { "v", "n" }, keys, tree_operate[action], options)
    elseif type(keys) == "table" then
      for _, k in ipairs(keys) do
        pcall(vim.keymap.set, k, tree_operate[action], options)
      end
    end
  end
end

---@param bookmark_lists Bookmarks.BookmarkList[]
function M.render(bookmark_lists)
  local context, lines = render_context.from_bookmark_lists(bookmark_lists)
  local created = menu_popup_window(lines)

  vim.b[created.buf]._bm_context = context

  register_local_shortcuts(created.buf)

  vim.g.bookmark_list_win_ctx = created
end

return M
