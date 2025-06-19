# Advanced Usage

In this section, we will cover some advanced usage of the bookmarks.nvim plugin.

Mostly, how users can customise the plugin to fits their needs programmatically.

## Quick Mark
> @obszczymucha https://github.com/LintaoAmons/bookmarks.nvim/pull/75

```lua
---@param input string
local function toggle_mark(input)
  Service.toggle_mark(input)
  Sign.safe_refresh_signs()
  pcall(Tree.refresh)
end

M.toggle_quick_mark = function()
  toggle_mark("")
end

vim.api.nvim_create_user_command("BookmarksQuickMark", bookmarks.toggle_quick_mark, {
  desc = "Toggle bookmark for the current line into active BookmarkList (no name).",
})
```

## Automaticalyy switching Active List based on repository
> Thx: @fantasygiveup https://github.com/LintaoAmons/bookmarks.nvim/issues/26

```lua
local M = {}

M.config = function()
  require("bookmarks").setup({})

  vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("BookmarksGroup", {}),
    pattern = { "*" },
    callback = M.find_or_create_project_bookmark_group,
  })
end

M.find_or_create_project_bookmark_group = function()
  local project_root = require("project_nvim.project").get_project_root()
  if not project_root then
    return
  end

  local project_name = string.gsub(project_root, "^" .. os.getenv("HOME") .. "/", "")
  local Service = require("bookmarks.domain.service")
  local Repo = require("bookmarks.domain.repo")
  local bookmark_list = nil

  for _, bl in ipairs(Repo.find_lists()) do
    if bl.name == project_name then
      bookmark_list = bl
      break
    end
  end

  if not bookmark_list then
    bookmark_list = Service.create_list(project_name)
  end
  Service.set_active_list(bookmark_list.id)
  require("bookmarks.sign").safe_refresh_signs()
end

return M
```

## Neo-tree Integration

You can integrate `bookmarks.nvim` with [Neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) to mark files or all files within a directory directly from the Neo-tree interface. This allows you to quickly bookmark items while navigating your project structure.

To enable this, add a custom mapping to your Neo-tree configuration. Here's an example of how you can set up a keymap (e.g., `<leader>bm`) to mark the selected file or all files in the selected directory:

```lua
-- In your Neo-tree setup (e.g., in the `opts.window.mappings` section)

-- Helper function to get all files from a node (file or directory)
local function get_all_files_from_node(node)
  local files = {}
  local vim_fs = require("vim.fs")

  if not node or not node.type or not node.path then
    return files -- Return empty if node is invalid
  end

  if node.type == "file" then
    table.insert(files, node.path)
  elseif node.type == "directory" then
    local function traverse_directory(current_dir_path)
      -- Use an on_error callback to silently skip directories that can't be read
      local iter = vim_fs.dir(current_dir_path, { on_error = function() end })
      if not iter then
        return
      end

      for name, type in iter do
        local full_path = vim_fs.joinpath(current_dir_path, name)
        if type == "file" then
          table.insert(files, full_path)
        elseif type == "directory" then
          traverse_directory(full_path) -- Recurse for subdirectories
        end
      end
    end
    traverse_directory(node.path)
  end
  return files
end

-- Add this to your neo-tree opts:
-- require("neo-tree").setup({
--   -- ... your other neo-tree config ...
--   window = {
--     mappings = {
--       -- ... your other mappings ...
--       ["<c-a>"] = { -- Or any keymap you prefer
--         function(state)
--           local node = state.tree:get_node()
--           if not node then
--             vim.notify("No node selected in Neo-tree", vim.log.levels.WARN)
--             return
--           end
--
--           local files_to_mark = get_all_files_from_node(node)
--
--           if #files_to_mark == 0 then
--             vim.notify("No files found to bookmark for: " .. node.path, vim.log.levels.INFO)
--             return
--           end
--
--           local bookmarks_api = require("bookmarks.api")
--           local marked_count = 0
--           for _, file_path in ipairs(files_to_mark) do
--             -- markfile returns the new bookmark id or nil, and an error message if any
--             local _, err = bookmarks_api.markfile(file_path)
--             if err then
--                vim.notify("Error bookmarking " .. file_path .. ": " .. err, vim.log.levels.ERROR)
--             else
--                marked_count = marked_count + 1
--             end
--           end
--
--           if marked_count > 0 then
--             vim.notify("Bookmarked " .. marked_count .. " file(s) from Neo-tree.", vim.log.levels.INFO)
--             -- Optionally, refresh bookmarks signs and tree if desired
--             -- require("bookmarks.sign").safe_refresh_signs()
--             -- pcall(require("bookmarks.tree.operate").refresh)
--           end
--         end,
--         desc = "Bookmark file/directory from Neo-tree",
--       },
--       -- ... your other mappings ...
--     },
--   },
--   -- ... your other neo-tree config ...
-- })
```

This mapping will:
1. Get the currently selected node in Neo-tree.
2. If it's a file, it will mark that file.
3. If it's a directory, it will recursively find all files within that directory and mark each of them.
4. Provide notifications for the actions taken.

You can adapt the `get_all_files_from_node` helper or use your own logic if needed. The `bookmarks.api.markfile(filepath)` function is used to create the bookmark.

