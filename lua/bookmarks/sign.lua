local Repo = require("bookmarks.domain.repo")
local Node = require("bookmarks.domain.node")
local ns_name = "BookmarksNvim"
local hl_name = "BookmarksNvimSign"
local hl_name_line = "BookmarksNvimLine"
local ns = vim.api.nvim_create_namespace(ns_name)

---@class Signs
---@field mark Sign
---@field desc_format function(string):string
-- ---@field annotation Sign -- TODO:

---@class Sign
---@field icon string
---@field color? string
---@field line_bg? string

local M = {}

---@param signs Signs
function M.setup(signs)
  local mark = signs.mark
  vim.fn.sign_define(hl_name, { text = mark.icon, texthl = hl_name })
  if mark.color then
    vim.api.nvim_set_hl(0, hl_name, { foreground = mark.color })
  end
  if mark.line_bg then
    vim.api.nvim_set_hl(0, hl_name_line, { bg = mark.line_bg })
  end
end

---@param line number
function M.place_sign(line, buf_number, desc)
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

function M.clean()
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

---@param bookmarks? Bookmarks.Node[]
function M._refresh_signs(bookmarks)
  M.clean()

  local active_list = Repo.ensure_and_get_active_list()

  bookmarks = bookmarks or Node.get_all_bookmarks(active_list)
  local buf_number = vim.api.nvim_get_current_buf()
  for _, bookmark in ipairs(bookmarks) do
    local filepath = vim.fn.expand("%:p")
    if filepath == bookmark.location.path then
      local desc = vim.g.bookmarks_config.signs.desc_format(bookmark)
      pcall(M.place_sign, bookmark.location.line, buf_number, desc)
    end
  end
end

---@param bookmarks? Bookmarks.Node[]
function M.safe_refresh_signs(bookmarks)
  pcall(M._refresh_signs, bookmarks)
end

return M
