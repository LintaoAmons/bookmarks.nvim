local Repo = require("bookmarks.domain.repo")
local Window = require("bookmarks.utils.window")

local M = {}

local function node_to_tree_str(node, depth)
  depth = depth or 0
  local indent = string.rep("  ", depth)
  local result = indent .. "- "

  if node.type == "list" then
    -- Handle list node
    result = result .. "**" .. node.name .. "**\n"

    -- Group bookmarks by filename
    local files = {}
    for _, child in ipairs(node.children) do
      if child.type == "bookmark" and child.location then
        local filepath = vim.fn.fnamemodify(child.location.path, ":~:.")
        files[filepath] = files[filepath] or {}
        table.insert(files[filepath], child)
      end
    end

    -- Output grouped bookmarks
    for filepath, bookmarks in pairs(files) do
      result = result .. indent .. "  - " .. filepath .. "\n"
      for _, bookmark in ipairs(bookmarks) do
        local content = bookmark.content and (": " .. bookmark.content) or ""
        result = result .. indent .. "    - " .. bookmark.location.line .. ": " .. bookmark.name .. content .. "\n"
      end
    end
  else
    -- Handle single bookmark node
    if node.location then
      local content = node.content and (": " .. node.content) or ""
      result = result .. string.format("%d: %s%s\n", node.location.line, node.name, content)
    end
  end

  return result
end

---Get info of bookmarks
function M.get_info()
  local sections = {
    "# Bookmarks Info\n",
  }

  -- Active list section
  local active_list = Repo.get_active_list()
  table.insert(sections, "## Active List\n")
  table.insert(sections, node_to_tree_str(active_list))

  -- Statistics section
  local all_bookmarks = Repo.get_all_bookmarks()
  local all_lists = Repo.find_lists()
  table.insert(sections, "## Statistics\n")
  table.insert(sections, string.format("- Total Bookmarks: `%d`\n", #all_bookmarks))
  table.insert(sections, string.format("- Total Lists: `%d`\n", #all_lists))
  table.insert(sections, string.format("- Database Location: `%s`\n", Repo._DB.uri))

  -- Configuration section
  table.insert(sections, "## Configuration\n")
  table.insert(sections, "```lua")
  local config = vim.g.bookmarks_config or {}
  for key, value in pairs(config) do
    if type(value) ~= "function" then
      table.insert(sections, string.format("%s = %s", key, vim.inspect(value)))
    end
  end
  table.insert(sections, "```")
  return sections
end

function M.open()
  local sections = M.get_info()
  -- Create popup window
  local popup = Window.new_popup_window()

  -- Set buffer content
  vim.api.nvim_buf_set_lines(popup.buf, 0, -1, false, vim.split(table.concat(sections, "\n"), "\n"))

  -- Set buffer options
  vim.api.nvim_buf_set_option(popup.buf, "modifiable", false)
  vim.api.nvim_buf_set_option(popup.buf, "filetype", "markdown")

  -- Set buffer keymaps
  vim.api.nvim_buf_set_keymap(popup.buf, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(popup.buf, "n", "<Esc>", "<cmd>close<CR>", { noremap = true, silent = true })

  -- Set window options
  vim.api.nvim_win_set_option(popup.win, "wrap", false)
  vim.api.nvim_win_set_option(popup.win, "cursorline", true)
end

return M
