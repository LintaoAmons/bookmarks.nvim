local Render = require("bookmarks.tree.render")
local Repo = require("bookmarks.domain.repo")
local Operate = require("bookmarks.tree.operate")
local Highlight = require("bookmarks.tree.render.highlight")

local M = {}

---@param opts {width: integer}
---@return integer
local function create_vsplit_with_width(opts)
  vim.cmd("vsplit")

  local new_win = vim.api.nvim_get_current_win()

  vim.api.nvim_win_set_width(new_win, opts.width)

  return new_win
end

---@class Bookmarks.ActionNodeInfo
---@field type 'list' | 'bookmark'
---@field path string
---@field dirname string

---@alias Bookmarks.KeymapCustomAction fun(node: Bookmarks.Node, info: Bookmarks.ActionNodeInfo): nil

--- buildNodeInfo out of node
---@param node Bookmarks.Node
---@return Bookmarks.ActionNodeInfo
local function buildNodeInfo(node)
  return {
    path = node.location.path,
    dirname = vim.fn.fnamemodify(node.location.path, ":h"),
    type = node.type,
  }
end

---@param custom_function Bookmarks.KeymapCustomAction
local function custom_action_wrapper(custom_function)
  local ctx = require("bookmarks.tree.ctx").get_ctx()
  local line_no = vim.api.nvim_win_get_cursor(0)[1]
  local line_ctx = ctx.lines_ctx.lines_ctx[line_no]

  if line_ctx then
    local node = require("bookmarks.domain.repo").find_node(line_ctx.id)
    if node then
      custom_function(node, buildNodeInfo(node))
    end
  end
end

local function register_local_shortcuts(buf)
  local keymap = vim.g.bookmarks_config.treeview.keymap or {}

  local default_options = {
    noremap = true,
    silent = true,
    nowait = true,
    buffer = buf,
  }

  -- Register all keymaps
  for key, mapping in pairs(keymap) do
    local action = mapping.action
    local opts = vim.tbl_extend("force", default_options, {
      desc = mapping.desc or ("BookmarksTree: " .. key),
    })

    if type(action) == "string" then
      -- Predefined action from Operate module
      local ok, _ = pcall(vim.keymap.set, { "n" }, key, Operate[action], opts)
      if not ok then
        vim.notify(
          "BookmarksTree: Failed to set keymap for '" .. key .. "' with action '" .. action .. "'",
          vim.log.levels.WARN
        )
      end
    elseif type(action) == "function" then
      -- Custom function provided by user
      pcall(vim.keymap.set, { "n" }, key, function()
        custom_action_wrapper(action)
      end, opts)
    end
  end
end

local function setup_highlights()
  Highlight.setup_highlights()
end

---Toggle the tree view
function M.toggle()
  setup_highlights()

  local cur_window = vim.api.nvim_get_current_win()
  local ctx = vim.g.bookmark_tree_view_ctx

  -- Handle existing tree view
  if ctx and vim.api.nvim_win_is_valid(ctx.win) then
    if cur_window == ctx.win then
      -- Close tree view when it's focused
      vim.api.nvim_win_close(ctx.win, true)
      vim.g.bookmark_tree_view_ctx = nil

      -- Return to previous window if valid
      if ctx.previous_window and vim.api.nvim_win_is_valid(ctx.previous_window) then
        vim.api.nvim_set_current_win(ctx.previous_window)
      end
      return
    end

    -- Switch to existing tree view
    vim.api.nvim_set_current_win(ctx.win)
    return
  end

  -- Create new tree view
  local buf = vim.api.nvim_create_buf(false, true)
  -- Set the filetype for the buffer using the newer API
  vim.bo[buf].filetype = "BookmarksTree"
  vim.bo[buf].swapfile = false
  vim.bo[buf].bufhidden = "wipe"
  local win = create_vsplit_with_width({ width = vim.g.bookmarks_config.treeview.window_split_dimension })
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false

  register_local_shortcuts(buf)
  vim.g.bookmark_tree_view_ctx = {
    buf = buf,
    win = win,
    previous_window = cur_window,
  }

  local node = Repo.ensure_and_get_active_list()
  Render.refresh(node)
end

---refresh the tree view with a new root node
---@param root_id number
function M.refresh(root_id)
  Operate.refresh(root_id)
end

return M
