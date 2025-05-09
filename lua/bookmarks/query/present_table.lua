local api = vim.api

---@alias PageState "" | "data" | "help"

---@class LocalKeys
---@field modes string[]
---@field keys string[]
---@field action string|function

---@class FormatterOptions
---@field borders BorderConfig
---@field truncate_marker string
---@field default_width? number
---@field max_width? number
---@field columns_order? string[] # List of column keys in desired order

--- Present a table[] of data in a floating window
--- table elements must be in same struct
--- +------------------------------------------+
--- |             Window Title                 |
--- +------------------------------------------+
--- |           _help_header[]                 |
--- |     (Header for help section)            |
--- +------------------------------------------+
--- |       _before_data_sections[][]          |
--- |  +------------------------------------+  |
--- |  |     _before_data_section[]         |  |
--- |  +------------------------------------+  |
--- |  +------------------------------------+  |
--- |  |     _before_data_section[]         |  |
--- |  +------------------------------------+  |
--- +------------------------------------------+
--- |                                          |
--- |          _current_data[]                 |
--- |        (Main data section)               |
--- |                                          |
--- +------------------------------------------+
--- |        _after_data_sections[][]          |
--- |  +------------------------------------+  |
--- |  |      _after_data_section[]         |  |
--- |  +------------------------------------+  |
--- |  +------------------------------------+  |
--- |  |      _after_data_section[]         |  |
--- |  +------------------------------------+  |
--- +------------------------------------------+
---@class PresentView
---@field win_id number|nil
---@field buf_id number|nil
---@field win_config table
---@field _help_header string[] # Header for help section to render
---@field _before_data_sections string[][] # Before data sections to render
---@field _current_data string[] # Current data to render
---@field _after_data_sections string[] # After data sections to render
---@field _keys table # TODO: buffer local keybindings
---@field _data_format_opts FormatterOptions
local PresentView = {
  win_id = nil,
  buf_id = nil,
  win_config = {
    relative = "editor",
    row = 1,
    col = 1,
    width = math.floor(vim.o.columns * 0.8),
    height = math.floor(vim.o.lines * 0.8),
    border = "rounded",
    title = "Bookmarks.nvim",
    title_pos = "center",
    style = "minimal",
  },
  _help_header = {
    "",
    "<localleader>f: Add filter condition",
    "<localleader>d: reset filter condition",
    "",
  },
  _before_data_sections = {},
  _current_data = {},
  _after_data_sections = {},
  _keys = {},
  _data_format_opts = {},
}
PresentView.__index = PresentView

---@param data? table[]
---@param keys? LocalKeys[]
---@param opts? FormatterOptions
---@return PresentView
function PresentView:new(data, keys, opts)
  local o = {}
  if data then
    self:set_data(data, opts)
  end
  self._keys = keys or {}
  return setmetatable(o, self)
end

---@param buf number
---@param keymap LocalKeys[]
local function register_local_shortcuts(buf, keymap)
  -- Validate buffer exists
  if not vim.api.nvim_buf_is_valid(buf) then
    vim.notify("Invalid buffer id: " .. buf, vim.log.levels.ERROR)
    return
  end

  for _, mapping in ipairs(keymap) do
    -- Validate required fields
    if not mapping.modes or not mapping.keys or not mapping.action then
      vim.notify("Invalid keymap structure", vim.log.levels.ERROR)
      return
    end

    for _, mode in ipairs(mapping.modes) do
      for _, key in ipairs(mapping.keys) do
        vim.keymap.set(mode, key, mapping.action, {
          buffer = buf,
          desc = "Keymap for mode: " .. mode,
          nowait = true,
          silent = true,
        })
      end
    end
  end
end

---@param opts {filetype?: string}
function PresentView:_layout(opts)
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

function PresentView:close()
  if self.buf_id and api.nvim_buf_is_valid(self.buf_id) then
    api.nvim_buf_delete(self.buf_id, { force = true })
  end
  if self.win_id and api.nvim_win_is_valid(self.win_id) then
    api.nvim_win_close(self.win_id, true)
  end
  self.buf_id = nil
  self.win_id = nil
end

function PresentView:_center_window()
  self.win_config.row = math.floor((vim.o.lines - self.win_config.height) / 2)
  self.win_config.col = math.floor((vim.o.columns - self.win_config.width) / 2)
  api.nvim_win_set_config(self.win_id, self.win_config)
end

function PresentView:_auto_resize()
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

---@class InferredColumn
---@field name string
---@field width number
---@field key string
---@field type string

--- Convert a table[] to a formatted string table
--- elements of table[] must be in same struct
---@param data table[] data rows, elements must be in same struct
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
    columns_order = {},
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
    local ordered_columns = {}

    -- First, collect all valid columns
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
          columns[key] = col
        end
      end
    end

    -- Handle columns specified in columns_order first
    for _, key in ipairs(opts.columns_order) do
      if columns[key] then
        table.insert(ordered_columns, columns[key])
        columns[key] = nil
      end
    end

    -- Add remaining columns alphabetically
    local remaining = {}
    for _, col in pairs(columns) do
      table.insert(remaining, col)
    end
    table.sort(remaining, function(a, b)
      return a.key < b.key
    end)

    -- Combine ordered and remaining columns
    for _, col in ipairs(remaining) do
      table.insert(ordered_columns, col)
    end

    return ordered_columns
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

---@param t1 string[]
---@param t2 string[]
---@return string[]
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

--- set _current_data by raw data
---@param raw_data table[]
---@param opts? FormatterOptions
function PresentView:set_data(raw_data, opts)
  self._data_format_opts = vim.tbl_deep_extend("force", self._data_format_opts, opts or {})
  self._current_data = format_table(raw_data, self._data_format_opts)
end

--- add a new section to _before_data_sections
---@param text string[]
function PresentView:add_before_data_section(text)
  table.insert(self._before_data_sections, text)
end

function PresentView:reset_before_data_sections()
  self._before_data_sections = {}
end

---Toggle open the present view window
function PresentView:toggle()
  if self.win_id and api.nvim_win_is_valid(self.win_id) then
    api.nvim_win_close(self.win_id, true)
  else
    self:render()
  end
end

function PresentView:_setup_win_buf()
  if not self.buf_id or not api.nvim_buf_is_valid(self.buf_id) then
    self.buf_id = api.nvim_create_buf(false, true)
  end

  if not self.win_id or not api.nvim_win_is_valid(self.win_id) then
    self.win_id = api.nvim_open_win(self.buf_id, true, self.win_config)
  end

  self:_center_window()
end

---@param arr string[][] The 2D array to flatten
---@return string[] The flattened 1D array
local function flatten_array(arr)
  local result = {}
  for _, inner_arr in ipairs(arr) do
    for _, value in ipairs(inner_arr) do
      table.insert(result, value)
    end
  end
  return result
end

---Render the present view based on the current _state
function PresentView:render()
  self:_setup_win_buf()
  if not self.buf_id or not api.nvim_buf_is_valid(self.buf_id) then
    vim.notify("PresentView: Buffer is not valid", vim.log.levels.ERROR, { title = "Bookmarks.nvim" })
    return
  end
  local before_data_contents = flatten_array(self._before_data_sections)
  local after_data_contents = flatten_array(self._after_data_sections)
  local contents = table_concat(self._help_header, before_data_contents)
  contents = table_concat(contents, self._current_data)
  contents = table_concat(contents, after_data_contents)
  api.nvim_buf_set_lines(self.buf_id, 0, -1, false, contents)
  vim.wo[self.win_id].cursorline = true
  register_local_shortcuts(self.buf_id, self._keys)
end

return PresentView
