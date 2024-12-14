local api = vim.api
local ACTIVE_LIST_HL_GROUP = "BookmarksTreeActiveList"
local ns_id = api.nvim_create_namespace("bookmarks_active_list")

local M = {}

function M.setup_highlights()
  api.nvim_set_hl(0, ACTIVE_LIST_HL_GROUP, {
    bg = "#2C323C",
    default = true,
  })
end

function M.clear_active_highlight(bufnr)
  api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
end

function M.set_active_highlight(bufnr, line)
  M.clear_active_highlight(bufnr)
  api.nvim_buf_set_extmark(bufnr, ns_id, line - 1, 0, {
    line_hl_group = ACTIVE_LIST_HL_GROUP,
    priority = 10,
  })
end

-- Main function to highlight active list
function M.highlight_active_list(bufnr, active_list_id, lines_ctx)
  M.clear_active_highlight(bufnr)

  -- Find the line number for the active list
  for line_num, ctx in ipairs(lines_ctx) do
    if ctx.id == active_list_id then
      M.set_active_highlight(bufnr, line_num)
      break
    end
  end
end

return M
