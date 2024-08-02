local tree_operate = require("bookmarks.tree.operate")
local config = require("bookmarks.config")

local M = {}

---@class Bookmarks.PopupWindowCtx
---@field buf integer
---@field win integer

---@param popup_content string[]
---@return Bookmarks.PopupWindowCtx
local function menu_popup_window(popup_content)
  local popup_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, popup_content)
  local width = vim.fn.strdisplaywidth(table.concat(popup_content, "\n"))
  local height = #popup_content

  local opts = {
    relative = "cursor",
    row = 0,
    col = 0,
    width = width + 1,
    height = height,
    style = "minimal",
    border = "single",
    title = "ContextMenu.",
  }

  vim.api.nvim_buf_set_option(popup_buf, "modifiable", false)
  local win = vim.api.nvim_open_win(popup_buf, true, opts)
  return {
    buf = popup_buf,
    win = win,
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
      vim.keymap.set({ "v", "n" }, keys, tree_operate[action], options)
    elseif type(keys) == "table" then
      for _, k in ipairs(keys) do
        vim.keymap.set({ "v", "n" }, k, tree_operate[action], options)
      end
    end
  end
end

---@param bookmark_lists Bookmarks.BookmarkList[]
function M.render(bookmark_lists)
  local context, lines = require("bookmarks.tree.context").from_bookmark_lists(bookmark_lists)
  local created = menu_popup_window(lines)

  vim.b[created.buf]._bm_context = context

  register_local_shortcuts(created.buf)

  vim.g.bookmark_list_win_ctx = created
  --
  -- vim.keymap.set({ "v", "n" }, "<CR>", function()
  --   quit_after_action(function()
  --     local line = vim.api.nvim_get_current_line()
  --     vim.print(line)
  --   end, created.win)
  -- end, {
  --   noremap = true,
  --   silent = true,
  --   nowait = true,
  --   buffer = created.buf,
  -- })
  --
  -- vim.keymap.set({ "v", "n" }, "g?", function()
  --   vim.print("<q> quit; <CR> trigger action under cursor")
  -- end, {
  --   noremap = true,
  --   silent = true,
  --   nowait = true,
  --   buffer = created.buf,
  -- })
  --
end

return M
