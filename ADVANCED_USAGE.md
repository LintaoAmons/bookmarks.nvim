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

