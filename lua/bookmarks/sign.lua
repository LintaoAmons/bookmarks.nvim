local repo = require("bookmarks.repo")
local ns_name = "BookmarksNvim"
local hl_name = "BookmarksNvimSign"
local hl_name_line = "BookmarksNvimLine"
local ns = vim.api.nvim_create_namespace(ns_name)

---@class Signs
---@field mark Sign
-- ---@field annotation Sign -- TODO:

---@class Sign
---@field icon string
---@field color? string
---@field line_bg? string

---@param signs Signs
local function setup(signs)
  for k, _ in pairs(signs) do
    vim.fn.sign_define(hl_name, { text = signs[k].icon, texthl = hl_name })
    if signs[k].color then
      vim.api.nvim_set_hl(0, hl_name, { foreground = signs[k].color })
    end
    if signs[k].line_bg then
      vim.api.nvim_set_hl(0, hl_name_line, { bg = signs[k].line_bg })
    end
  end
end

---@param line number
local function place_sign(line, buf_number, desc)
  vim.fn.sign_place(line, ns_name, hl_name, buf_number, { lnum = line })
  local at_end = -1
  local row = line - 1
  vim.api.nvim_buf_set_extmark(buf_number, ns, row, at_end, {
    virt_text = { { "  " .. desc, hl_name } },
    virt_text_pos = "overlay",
    hl_group = hl_name,
    hl_mode = "combine",
  })

  -- Get the length of the current line
  local line_length = #(vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or "")
  vim.api.nvim_buf_set_extmark(buf_number, ns, line - 1, 0, {
    end_row = row,
    end_col = line_length,
    hl_group = hl_name_line,
  })
end

local function clean()
  pcall(vim.fn.sign_unplace, ns_name)
  local all = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
  for _, extmark in ipairs(all) do
    vim.api.nvim_buf_del_extmark(0, ns, extmark[1])
  end

  -- Optionally remove line highlights here
  for _, line_ind in ipairs(all) do
    -- Assume desc can provide the unique identifier. You may consider further adjustments based on your logic.
    -- local hl_line_name = "BookmarksNvimLine" .. line_ind[3]  -- Extract the correct identifier for cleanup
    vim.api.nvim_buf_clear_namespace(0, ns, line_ind[1] - 1, line_ind[1])
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

local function clean_tree_cache(buf)
  vim.b[buf]._bm_context = nil
  vim.b[buf]._bm_tree_cut = nil
end

local function refresh_tree()
  local ctx = vim.g.bookmark_list_win_ctx
  if ctx == nil then
    return
  end

  clean_tree_cache(ctx.buf)

  local bookmark_lists = repo.bookmark_list.read.find_all()
  local context, lines = require("bookmarks.tree.context").from_bookmark_lists(bookmark_lists)

  vim.api.nvim_buf_set_option(ctx.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(ctx.buf, 'modifiable', false)

  vim.b[ctx.buf]._bm_context = context
end

return {
  setup = setup,
  bookmark_sign_autocmd = bookmark_sign_autocmd,
  refresh_signs = safe_refresh_signs,
  refresh_tree = refresh_tree,
  namespace = {
    ns = ns,
    hl_name = hl_name,
  }
}
