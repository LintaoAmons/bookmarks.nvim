local api = vim.api

---@class PresentTable
---@field win_id number|nil
---@field buf_id number|nil
---@field win_config table
---@field _state table
---@field _data string[]
---@field _help string[]
---@field _help_header string[]
local M = {
  win_id = nil,
  buf_id = nil,
  win_config = {
    relative = "editor",
    row = 1,
    col = 1,
    width = 110,
    height = 40,
    border = "rounded",
    title = "Bookmarks.nvim",
    title_pos = "center",
    style = "minimal", -- Optional: "minimal", "underline", "double"
  },
  _state = {
    page = "", -- "plugins", "help"
  },
  _data = {},
  _help = {
    "      Bookmark.nvim Help",
    "",
    "  This plugin lists all your plugins based on",
    "  the last commit date so that you can easily",
    "  identify plugins that are not actively",
    "  maintained.",
    "",
    "  Keybindings:",
    "",
    "  * N: Sort plugins by Name (coming soon)",
    "  * C: Sort plugins by Commit Date (coming soon)",
    "  * j/k or <C-e>/<C-y>: Scroll up/down",
    "  * <C-d>/<C-u>: Scroll up/down half page",
    "  * q: Close the window",
    "  * ?: Toggle help",
    "",
    "  (More help coming soon...)",
  },
  _help_header = {
    "",
    " This only shows loaded plugins ",
    string.format("%-15s %-20s %s", "<q>: Close", "<?>: Toggle Help", "<C-u>/<C-d>: Half Page Up/Down"),
    "",
  },
}

---@return PresentTable
function M:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  return o
end

---@param opts {filetype?: string}
function M:_layout(opts)
  if not self.buf_id or not api.nvim_buf_is_valid(self.buf_id) then
    self.buf_id = api.nvim_create_buf(false, true)
    if opts.filetype then
      vim.bo[self.buf_id].filetype = opts.filetype
    end
  end
  if not self.win_id or not api.nvim_win_is_valid(self.win_id) then
    self.win_id = api.nvim_open_win(self.buf_id, true, self.win_config)
  end
  self:_center_window()
  -- self:_auto_resize()
end

function M:close()
  if self.buf_id and api.nvim_buf_is_valid(self.buf_id) then
    api.nvim_buf_delete(self.buf_id, { force = true })
  end
  if self.win_id and api.nvim_win_is_valid(self.win_id) then
    api.nvim_win_close(self.win_id, true)
  end
  self.buf_id = nil
  self.win_id = nil
  self._state.page = ""
end

function M:_center_window()
  self.win_config.row = math.floor((vim.o.lines - self.win_config.height) / 2)
  self.win_config.col = math.floor((vim.o.columns - self.win_config.width) / 2)
  api.nvim_win_set_config(self.win_id, self.win_config)
end

function M:_auto_resize()
  api.nvim_create_autocmd({ "VimResized" }, {
    buffer = self.buf_id,
    callback = function()
      self:_center_window()
    end,
  })
end

---@class BorderConfig
---@field top_separator string
---@field column_separator string
---@field cross_separator string

---@class FormatterOptions
---@field borders BorderConfig
---@field truncate_marker string
---@field default_width? number
---@field max_width? number

---@class InferredColumn
---@field name string
---@field width number
---@field key string
---@field type string

---@param data table[]
---@param opts? FormatterOptions
---@return string[]
local function format_table(data, opts)
  if #data == 0 then
    return {}
  end

  opts = opts or {}
  ---@type FormatterOptions
  local default_opts = {
    borders = {
      top_separator = "─",
      column_separator = "│",
      cross_separator = "┼",
    },
    truncate_marker = "…",
    default_width = 20,
    max_width = 50,
  }
  opts = vim.tbl_deep_extend("force", default_opts, opts)

  ---@param value any
  ---@return string
  local function get_type(value)
    return type(value) == "table" and "table" or type(value)
  end

  ---@param sample table
  ---@return InferredColumn[]
  local function infer_columns(sample)
    local columns = {}
    local seen = {}

    for key, value in pairs(sample) do
      if not seen[key] and type(key) == "string" then
        seen[key] = true
        local val_type = get_type(value)
        if val_type ~= "function" and val_type ~= "table" then
          ---@type InferredColumn
          local col = {
            name = key,
            key = key,
            type = val_type,
            width = math.min(opts.max_width or 50, math.max(#key, opts.default_width or 20)),
          }
          table.insert(columns, col)
        end
      end
    end

    -- Sort columns alphabetically
    table.sort(columns, function(a, b)
      return a.key < b.key
    end)
    return columns
  end

  ---@param columns InferredColumn[]
  ---@return string[]
  local function create_header(columns)
    local headers = {}
    local separators = {}

    for i, col in ipairs(columns) do
      headers[i] = string.format("%-" .. col.width .. "s", col.name)
      -- Create separator with same width as formatted header
      separators[i] = string.rep(opts.borders.top_separator, col.width)
    end

    local header_line = table.concat(headers, " " .. opts.borders.column_separator .. " ")
    local separator_line =
      table.concat(separators, string.rep(opts.borders.top_separator, #opts.borders.column_separator + 2))

    return {
      header_line,
      separator_line,
    }
  end
  ---@param item table
  ---@param columns InferredColumn[]
  ---@return string
  local function format_row(item, columns)
    local values = {}

    for i, col in ipairs(columns) do
      local value = item[col.key]
      value = tostring(value or "")

      if #value > col.width then
        value = string.sub(value, 1, col.width - 1) .. opts.truncate_marker
      end

      values[i] = string.format("%-" .. col.width .. "s", value)
    end

    return table.concat(values, " " .. opts.borders.column_separator .. " ")
  end

  local columns = infer_columns(data[1])
  local formatted = create_header(columns)

  for _, item in ipairs(data) do
    table.insert(formatted, format_row(item, columns))
  end

  return formatted
end

local function table_concat(t1, t2)
  local result = {}
  for _, v in ipairs(t1) do
    table.insert(result, v)
  end
  for _, v in ipairs(t2) do
    table.insert(result, v)
  end
  return result
end

---@param self PresentTable
---@param contents string[]
function M:_render(contents)
  vim.bo[self.buf_id].modifiable = true
  api.nvim_buf_set_lines(self.buf_id, 0, -1, false, contents)
  vim.bo[self.buf_id].modifiable = false
  vim.bo[self.buf_id].modified = false
end

function M:render_data()
  if not self.buf_id or not api.nvim_buf_is_valid(self.buf_id) then
    return
  end
  if self._state.page == "plugins" then
    return
  end
  self._state.page = "plugins"
  local contents = table_concat(self._help_header, self._data)
  self:_render(contents)
  vim.wo[self.win_id].cursorline = true
end

---@param self PresentTable
function M:render_help()
  if not self.buf_id or not api.nvim_buf_is_valid(self.buf_id) then
    return
  end
  if self._state.page == "help" then
    return
  end
  self._state.page = "help"
  local contents = table_concat(self._help_header, self._help)
  self:_render(contents)
end

---@param self PresentTable
function M:setup_keybindings()
  vim.keymap.set("n", "q", function()
    self:close()
  end, { buffer = self.buf_id })
  vim.keymap.set("n", "?", function()
    if self._state.page ~= "help" then
      self:render_help()
    else
      self:render_data()
    end
  end, { buffer = self.buf_id })
end

---@param data table[]
---@param opts? {filetype?: string}
---@return nil
function M:setup(data, opts)
  opts = opts or {}
  self:_layout(opts)
  if #self._data == 0 then
    self._data = format_table(data)
  end
  self._state.page = ""
  self:setup_keybindings()
  self:render_data()
end

return M