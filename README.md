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

### Basic Bookmark Operations

| Command            | Description                                                                                                                         |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| `BookmarksMark`    | Mark current line into active BookmarkList. Rename existing bookmark under cursor. Toggle it off if the new name is an empty string |
| `BookmarksNewList` | Create a new bookmark list                                                                                                          |
| `BookmarksDesc`    | Add description to the bookmark under cursor, if no bookmark, then mark it first                                                    |
| `BookmarksGoto`    | Go to bookmark at current active BookmarkList with telescope                                                                        |
| `BookmarksLists`   | Pick a bookmark list with telescope                                                                                                 |
| `BookmarksGrep`            | Grep through the content of all bookmarked files         |

> [!NOTE]
> Those Telescope shortcuts are also available

| Shortcut | Action for bookmarks                       | Action for lists                 |
| -------- | ------------------------------------------ | -------------------------------- |
| `Enter`  | Go to selected bookmark                    | set selected list as active list |
| `<C-x>`  | Open selected bookmark in horizontal split | -                                |
| `<C-v>`  | Open selected bookmark in vertical split   | -                                |
| `<C-t>`  | Open selected bookmark in new tab          | -                                |
| `<C-d>`  | Delete selected bookmark                   | Delete selected list             |

### Quick Navigation

| Command                   | Description                                                                         |
| ------------------------- | ----------------------------------------------------------------------------------- |
| `BookmarksGotoNext`       | Go to next bookmark in line number order within the current active BookmarkList     |
| `BookmarksGotoPrev`       | Go to previous bookmark in line number order within the current active BookmarkList |
| `BookmarksGotoNextInList` | Go to next bookmark by order id within the current active BookmarkList              |
| `BookmarksGotoPrevInList` | Go to next bookmark by order id within the current active BookmarkList              |

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

### Treeview

| Command         | Description                   |
| --------------- | ----------------------------- |
| `BookmarksTree` | Browse bookmarks in tree view |

> [!NOTE]
> There are quite a lot operations in treeview, which you can config it in the way you like.

```lua
-- default keybindings in the treeview buffer
keymap = {
  quit = { "q", "<ESC>" },      -- Close the tree view window and return to previous window
  refresh = "R",                -- Reload and redraw the tree view
  create_list = "a",            -- Create a new list under the current node
  level_up = "u",               -- Navigate up one level in the tree hierarchy
  set_root = ".",               -- Set current list as root of the tree view, also set as active list
  set_active = "m",             -- Set current list as the active list for bookmarks
  toggle = "o",                 -- Toggle list expansion or go to bookmark location
  move_up = "<localleader>k",   -- Move current node up in the list
  move_down = "<localleader>j", -- Move current node down in the list
  delete = "D",                 -- Delete current node
  rename = "r",                 -- Rename current node
  goto = "g",                   -- Go to bookmark location in previous window
  cut = "x",                    -- Cut node
  copy = "c",                   -- Copy node
  paste = "p",                  -- Paste node
  show_info = "i",              -- Show node info
  reverse = "t",                -- Reverse the order of nodes in the tree view
}
```

### Viewing and Information

| Command                        | Description                    |
| ------------------------------ | ------------------------------ |
| `BookmarksInfo`                | Overview plugin current status |
| `BookmarksInfoCurrentBookmark` | Show current bookmark info     |

### Utility Commands

| Command                    | Description                                              |
| -------------------------- | -------------------------------------------------------- |
| `BookmarksCommands`        | Find bookmark commands and trigger it                    |
| `BookmarkRebindOrphanNode` | Rebind orphaned nodes by attaching them to the root node |

### Keymap

This plugin doesn't provide any default keybinding. I recommend you to have these keybindings.

```lua
vim.keymap.set({ "n", "v" }, "mm", "<cmd>BookmarksMark<cr>", { desc = "Mark current line into active BookmarkList." })
vim.keymap.set({ "n", "v" }, "mo", "<cmd>BookmarksGoto<cr>", { desc = "Go to bookmark at current active BookmarkList" })
vim.keymap.set({ "n", "v" }, "ma", "<cmd>BookmarksCommands<cr>", { desc = "Find and trigger a bookmark command." })
```

## CONTRIBUTING

Don't hesitate to ask me anything about the codebase if you want to contribute.

- How to get started:
  1. `plugin/bookmarks.lua` the entry point of the plugin
  2. `lua/bookmarks/domain` where the main objects/concepts live

## Self-Promotion

- [my website](https://oatnil.top)
- [my neovim config](https://github.com/LintaoAmons/VimEverywhere/tree/main/nvim)
- [scratch.nvim](https://github.com/LintaoAmons/scratch.nvim)
- [cd-project.nvim](https://github.com/LintaoAmons/cd-project.nvim)
- [bookmarks.nvim](https://github.com/LintaoAmons/bookmarks.nvim)
- [context-menu.nvim](https://github.com/LintaoAmons/context-menu.nvim)
