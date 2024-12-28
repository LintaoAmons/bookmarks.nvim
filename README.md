# Bookmarks.nvim

- Simple: Add, Rename and Remove bookmarks with only one command, less shortcuts more productivity.
- Persistent: save your bookmarks into a sqlite db file
- Accessible: Find your bookmark by telescope or Treeview with ease.
- Informative: mark with a name or description, so you can record more information.
- Visibility: display icon and name at the marked lines, and highlight marked lines.
- Lists: arrange your bookmarks in lists, organise the bookmarks in your way.

<img width="1910" alt="image" src="https://github.com/user-attachments/assets/08806798-d87a-4191-b5d7-9259e50390c3" />

- [Basic function overview](https://www.youtube.com/watch?v=RoyXQYauiLo)

- [BookmarkTree function overview](https://youtu.be/TUCn1mqSI6Q)

## Install and Config

```lua
-- with lazy.nvim
return {
  "LintaoAmons/bookmarks.nvim",
  -- pin the plugin at specific version for stability
  -- backup your bookmark sqlite db when there are breaking changes
  -- tag = "v2.3.0",
  dependencies = {
    {"kkharji/sqlite.lua"},
    {"nvim-telescope/telescope.nvim"},
    {"stevearc/dressing.nvim"} -- optional: better UI
  },
  config = function()
    local opts = {} -- go to the following link to see all the options in the deafult config file
    require("bookmarks").setup(opts) -- you must call setup to init sqlite db
  end,
}

-- run :BookmarksInfo to see the running status of the plugin
```

Check the default config in [config.lua](./lua/bookmarks/config.lua)

## Usage

### Commands

| Command                        | Description                                                                                                                         |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| `BookmarksMark`                | Mark current line into active BookmarkList. Rename existing bookmark under cursor. Toggle it off if the new name is an empty string |
| `BookmarksGoto`                | Go to bookmark at current active BookmarkList                                                                                       |
| `BookmarksGotoNext`            | Go to next bookmark in line number order within the current active BookmarkList                                                     |
| `BookmarksGotoPrev`            | Go to previous bookmark in line number order within the current active BookmarkList                                                 |
| `BookmarksGotoNextInList`      | Go to next bookmark by order id within the current active BookmarkList                                                              |
| `BookmarksGotoPrevInList`      | Go to next bookmark by order id within the current active BookmarkList                                                              |
| `BookmarksDesc`                | Add description to the bookmark under cursor, if no bookmark, then mark it first                                                    |
| `BookmarksTree`                | Browse bookmarks in tree view                                                                                                       |
| `BookmarksCommands`            | Find bookmark commands and trigger it                                                                                               |
| `BookmarksInfo`                | Overview plugin current status                                                                                                      |
| `BookmarksInfoCurrentBookmark` | Show current bookmark info                                                                                                          |
| `BookmarksGrep`                | Grep through the content of all bookmarked files                                                                                    |
| `BookmarksLists`               | Pick a bookmark list                                                                                                                |
| `BookmarksNewList`             | Create a new bookmark list                                                                                                          |
| `BookmarkRebindOrphanNode`     | Rebind orphaned nodes by attaching them to the root node                                                                            |

### Keymap

This plugin doesn't provide any default keybinding. I recommend you to have these four keybindings.

```lua
vim.keymap.set({ "n", "v" }, "mm", "<cmd>BookmarksMark<cr>", { desc = "Mark current line into active BookmarkList." })
vim.keymap.set({ "n", "v" }, "mo", "<cmd>BookmarksGoto<cr>", { desc = "Go to bookmark at current active BookmarkList" })
vim.keymap.set({ "n", "v" }, "ma", "<cmd>BookmarksCommands<cr>", { desc = "Find and trigger a bookmark command." })
```

When using the bookmark picker (`:BookmarksGoto`), the following shortcuts are available:

| Shortcut | Action                                          |
| -------- | ----------------------------------------------- |
| `Enter`  | Go to selected bookmark                         |
| `<C-x>`  | Open selected bookmark in horizontal split      |
| `<C-v>`  | Open selected bookmark in vertical split        |
| `<C-t>`  | Open selected bookmark in new tab               |
| `<C-d>`  | Delete selected bookmark and refresh the picker |

You can also use `Hydra` to make `navigation` easier

```lua
-- use `nvimtools/hydra.nvim`: https://github.com/anuvyklack/hydra.nvim/issues/104
local Hydra = require('hydra')
Hydra({
  name = "Bookmarks",
  mode = 'n',
  body = '<leader>m',
  hint = [[
  Bookmark Navigation
  
  ^  _j_: Next in List     _J_: Next Bookmark
  ^  _k_: Prev in List     _K_: Prev Bookmark
  ^
  ^ _<Esc>_: Exit
  ]],
  heads = {
    { 'j', '<cmd>BookmarksGotoNextInList<cr>' },
    { 'k', '<cmd>BookmarksGotoPrevInList<cr>' },
    { 'J', '<cmd>BookmarksGotoNext<cr>' },
    { 'K', '<cmd>BookmarksGotoPrev<cr>' },
  },
})
```

## CONTRIBUTING

Don't hesitate to ask me anything about the codebase if you want to contribute.

By [telegram](https://t.me/+ssgpiHyY9580ZWFl) or [微信: CateFat](https://lintao-index.pages.dev/assets/images/wechat-437d6c12efa9f89bab63c7fe07ce1927.png)

- How to get started:
  1. `plugin/bookmarks.lua` the entry point of the plugin
  2. `lua/bookmarks/domain` where the main objects/concepts live

## Some Other Neovim Stuff

- [my neovim config](https://github.com/LintaoAmons/CoolStuffes/tree/main/nvim/.config/nvim)
- [scratch.nvim](https://github.com/LintaoAmons/scratch.nvim)
- [cd-project.nvim](https://github.com/LintaoAmons/cd-project.nvim)
- [bookmarks.nvim](https://github.com/LintaoAmons/bookmarks.nvim)
- [context-menu.nvim](https://github.com/LintaoAmons/context-menu.nvim)
