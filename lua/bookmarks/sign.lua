local repo = require("bookmarks.repo")
local ns_name = "BookmarksNvim"
local hl_name = "BookmarksNvimSign"
local ns = vim.api.nvim_create_namespace(ns_name)

---@class Signs
---@field mark Sign
-- ---@field annotation Sign -- TODO:

---@class Sign
---@field icon string
---@field color ?string

---@param signs Signs
local function setup(signs)
  for k, _ in pairs(signs) do
    vim.fn.sign_define(hl_name, { text = signs[k].icon, texthl = hl_name })
    vim.api.nvim_set_hl(0, hl_name, { foreground = signs[k].color })
  end
end

---@param line number
local function place_sign(line, buf_number, desc)
  vim.fn.sign_place(line, ns_name, hl_name, buf_number, { lnum = line })
  local at_end = -1
  vim.api.nvim_buf_set_extmark(buf_number, ns, line - 1, at_end, {
    virt_text = { { "  " .. desc, hl_name } },
    virt_text_pos = "overlay",
    hl_mode = "combine",
  })
end

local function clean()
  pcall(vim.fn.sign_unplace, ns_name)
  local all = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
  for _, extmark in ipairs(all) do
    vim.api.nvim_buf_del_extmark(0, ns, extmark[1])
  end
end

---@param bookmarks? Bookmarks.Bookmark[]
local function _refresh_signs(bookmarks)
  clean()

  bookmarks = bookmarks or repo.bookmark_list.write.find_or_set_active().bookmarks
  local buf_number = vim.api.nvim_get_current_buf()
  for _, bookmark in ipairs(bookmarks) do
    local filepath = vim.fn.expand("%:p")
    if filepath == bookmark.location.path then
      pcall(place_sign, bookmark.location.line, buf_number, bookmark.name)
    end
  end
end

---@param bookmarks? Bookmarks.Bookmark[]
local function safe_refresh_signs(bookmarks)
  pcall(_refresh_signs, bookmarks)
end

local function bookmark_sign_autocmd()
  -- TODO: check the autocmd
  vim.api.nvim_create_augroup(ns_name, { clear = true })
  vim.api.nvim_create_autocmd({ "BufWinEnter", "BufEnter" }, {
    group = ns_name,
    callback = function(_)
      safe_refresh_signs()
    end,
  })
end

local function refresh_tree()
  if vim.g.bookmark_list_win_ctx == nil then
    return
  end

  local ctx = vim.g.bookmark_list_win_ctx
  local bookmark_lists = repo.bookmark_list.read.find_all()
  local context, lines = require("bookmarks.tree.context").from_bookmark_lists(bookmark_lists)

  vim.api.nvim_buf_set_option(ctx.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(ctx.buf, 'modifiable', false)

  vim.b[ctx.buf].context = context
end

return {
  setup = setup,
  bookmark_sign_autocmd = bookmark_sign_autocmd,
  refresh_signs = safe_refresh_signs,
  refresh_tree = refresh_tree,
}
