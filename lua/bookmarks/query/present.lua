-- copy froma https://github.com/ZWindL/orphans.nvim/blob/main/lua/orphans/view/plugin_list.lua
-- define the structure of that window
-- structure is defined by buf
-- expose a render/redraw/update function that only accept fixed parameters
-- a close function to close the window
--
-- event handlers?
-- implemented by buffer only keybindings

-- functions
-- sort by last commit (C)
-- sort by name (N)
-- refresh (R)
-- fetch (F)
-- export (E)
-- help (?)

-- TODO:
-- [x] auto resizing
-- [ ] better keybinding logic
-- [ ] options

local api = vim.api

local M = {
  win_id = nil,
  buf_id = nil,
  config = {
    relative = "editor",
    row = 1,
    col = 1,
    width = 110,
    height = 40,
    border = "rounded",
    title = "Orphans.nvim",
    title_pos = "center",
    style = "minimal", -- Optional: "minimal", "underline", "double"
  },
  _state = {
    page = "", -- "plugins", "help"
  },
  _plugins = {},
  _help = {
    "      Orphans.nvim Help",
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

function M:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  return o
end

-- init the floating window
function M:_layout(opts)
  if not self.buf_id or not api.nvim_buf_is_valid(self.buf_id) then
    self.buf_id = api.nvim_create_buf(false, true)
    if opts.filetype then
      vim.bo[self.buf_id].filetype = opts.filetype
    end
  end
  if not self.win_id or not api.nvim_win_is_valid(self.win_id) then
    self.win_id = api.nvim_open_win(self.buf_id, true, self.config)
  end
  self:_center_window()
  self:_auto_resize()
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
  self.config.row = math.floor((vim.o.lines - self.config.height) / 2)
  self.config.col = math.floor((vim.o.columns - self.config.width) / 2)
  api.nvim_win_set_config(self.win_id, self.config)
end

function M:_auto_resize()
  api.nvim_create_autocmd({ "VimResized" }, {
    buffer = self.buf_id,
    callback = function()
      self:_center_window()
    end,
  })
end

local function format_plugin(plugin)
  local max_pname_len = 30
  local max_commit_msg_len = 40
  local name = plugin.name
  local last_update = plugin.last_commit_time_delta
  local last_commit_time = plugin.last_commit_time_str
  local last_commit_msg = plugin.last_commit_msg
  if string.len(plugin.name) > max_pname_len then
    name = string.sub(plugin.name, 1, max_pname_len - 1) .. "…"
  end
  if string.len(plugin.last_commit_msg) > max_commit_msg_len then
    last_commit_msg = string.sub(plugin.last_commit_msg, 1, max_commit_msg_len - 1) .. "…"
  end
  return string.format("%-32s │ %-15s │ %-10s: %-42s", name, last_update, last_commit_time, last_commit_msg)
end

local function table_concat(t1, t2)
  local t = vim.deepcopy(t1, true)
  for _, v in ipairs(t2) do
    table.insert(t, v)
  end
  return t
end

local function format_plugin_table(plugins)
  local t = {}
  -- format header
  table.insert(t, string.format("%-32s │ %-15s │ %-54s", "Name", "Last Update", "Last Commit"))
  -- format split line
  table.insert(t, string.rep("─", 33) .. "┼" .. string.rep("─", 17) .. "┼" .. string.rep("─", 58))
  for _, plugin in ipairs(plugins) do
    table.insert(t, format_plugin(plugin))
  end
  return t
end

function M:_render(contents)
  vim.bo[self.buf_id].modifiable = true
  api.nvim_buf_set_lines(self.buf_id, 0, -1, false, contents)
  vim.bo[self.buf_id].modifiable = false
  vim.bo[self.buf_id].modified = false
end

function M:render_plugins()
  if not self.buf_id or not api.nvim_buf_is_valid(self.buf_id) then
    return
  end
  if self._state.page == "plugins" then
    return
  end
  self._state.page = "plugins"
  local contents = table_concat(self._help_header, self._plugins)
  self:_render(contents)
  vim.wo[self.win_id].cursorline = true
end

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

function M:setup_keybindings()
  vim.keymap.set("n", "q", function()
    self:close()
  end, { buffer = self.buf_id })
  vim.keymap.set("n", "?", function()
    if self._state.page ~= "help" then
      self:render_help()
    else
      self:render_plugins()
    end
  end, { buffer = self.buf_id })
end

function M:setup(plugins, opts)
  self:_layout(opts)
  if #self._plugins == 0 then
    self._plugins = format_plugin_table(plugins)
  end
  self._state.page = ""
  self:setup_keybindings()
  self:render_plugins()
end

return M
