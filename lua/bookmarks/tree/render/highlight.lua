local api = vim.api
local ACTIVE_LIST_HL_GROUP = "BookmarksTreeActiveList"
local ns_id = api.nvim_create_namespace("bookmarks_active_list")

local M = {}

function M.setup_highlights()
  local config = vim.g.bookmarks_config.treeview.highlights.active_list
  api.nvim_set_hl(0, ACTIVE_LIST_HL_GROUP, {
    bg = config.bg,
    fg = config.fg,
    bold = config.bold,
    default = false, -- Allow overrides
  })
end

function M.clear_active_highlight(bufnr)
  api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
end

function M.set_active_highlight(bufnr, line)
  M.clear_active_highlight(bufnr)
  api.nvim_buf_add_highlight(bufnr, ns_id, ACTIVE_LIST_HL_GROUP, line - 1, 0, -1)
end

function M.highlight_active_list(bufnr, active_list_id, lines_ctx)
  if not api.nvim_buf_is_valid(bufnr) then
    return
  end

  M.clear_active_highlight(bufnr)

  for line_num, ctx in ipairs(lines_ctx) do
    if ctx.id == active_list_id then
      M.set_active_highlight(bufnr, line_num)
      break
    end
  end
end

return M
