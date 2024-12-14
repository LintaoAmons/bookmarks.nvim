local M = {}

---@class WindowOptions
---@field relative? "editor"|"win"|"cursor"|"mouse" # Window position relative to
---@field width? integer # Window width in cells
---@field height? integer # Window height in cells
---@field row? number # Row position in screen cells
---@field col? number # Column position in screen cells
---@field win? integer # Window ID for relative positioning
---@field anchor? "NW"|"NE"|"SW"|"SE" # Which corner to place at position
---@field bufpos? integer[] # Position relative to buffer text [line, column]
---@field focusable? boolean # Enable focus by user actions
---@field external? boolean # Display as external window
---@field zindex? integer # Stacking order (default: 50)
---@field style? "minimal" # Window appearance style
---@field border? "none"|"single"|"double"|"rounded"|"solid"|"shadow"|string[] # Border style
---@field title? string|table # Window title
---@field title_pos? "left"|"center"|"right" # Title position
---@field footer? string|table # Window footer
---@field footer_pos? "left"|"center"|"right" # Footer position
---@field noautocmd? boolean # Block autocommands during creation
---@field fixed? boolean # Keep window fixed when truncated
---@field hide? boolean # Hide the floating window
---@field vertical? boolean # Split vertically
---@field split? "left"|"right"|"above"|"below" # Split direction

---@type WindowOptions
local default_opts = {
  relative = "editor",
  col = 10,
  width = vim.api.nvim_get_option("columns") - 20,
  row = 5,
  height = vim.api.nvim_get_option("lines") - 10,
  style = "minimal",
  border = "double",
  focusable = true,
  zindex = 50,
}

---Create a new window
---@param buf? number?
---@param win_opts? WindowOptions
---@return {buf: integer, win: integer}
function M.new_window(buf, win_opts)
  buf = buf or vim.api.nvim_create_buf(false, false)
  local opts = win_opts or default_opts

  local win = vim.api.nvim_open_win(buf, true, opts)

  return {
    buf = buf,
    win = win,
  }
end

---Create a new floating window
---@return {buf: integer, win: integer}
function M.new_popup_window()
  return M.new_window()
end

-- :lua require("bookmarks.utils.window").description_window(buf)
function M.description_window()
  -- Get cursor position and screen dimensions
  local win_width = vim.api.nvim_win_get_width(0)
  local win_height = vim.api.nvim_win_get_height(0)
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local cursor_row = cursor_pos[1]
  local cursor_col = cursor_pos[2]

  -- Get cursor screen position
  local cursor_screen_pos = vim.fn.screenpos(0, cursor_row, cursor_col + 1)
  local screen_row = cursor_screen_pos.row

  -- Calculate dimensions from cursor to screen edges
  local width = math.max(48, win_width - cursor_col - 4)
  local height = win_height - screen_row - 4 -- Use screen position instead of buffer position

  local win = M.new_window(nil, {
    relative = "cursor",
    width = width,
    height = height,
    row = 0, -- Start at cursor position
    col = 1, -- Start one column after cursor
    style = "minimal",
    border = "rounded",
    zindex = 50,
  })
  return win
end

return M
