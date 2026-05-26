# Bookmarks.nvim

- Simple: Add, Rename and Remove bookmarks with only one command, less shortcuts more productivity.
- Persistent: save your bookmarks into a sqlite db file
- Accessible: Find your bookmark by snacks.nvim picker, telescope, or Treeview with ease.
- Informative: mark with a name or description, so you can record more information.
- Visibility: display icon and name at the marked lines, and highlight marked lines.
- Lists: arrange your bookmarks in lists, organise the bookmarks in your way.

<p align="center">
  <a href="#install-and-config">Install & Config</a>
  ·
  <a href="#basic-bookmark-operations">Basic Operations</a>
  ·
  <a href="#treeview">Treeview</a>
  ·
  <a href="#quick-navigation">Quick Navigation</a>
  ·
  <a href="#more-commands">More Commands</a>
  ·
  <a href="#keymap">Keymap</a>
  ·
  <a href="#contributing">Contributing</a>
</p>

![bookmarks nvim](https://github.com/user-attachments/assets/dd8ed4d0-8f36-4f32-b066-0594ef218df0)

- More usecases can be found at https://oatnil.top/bookmarks/usecases

- [Basic function overview](https://www.youtube.com/watch?v=RoyXQYauiLo)

- [BookmarkTree function overview](https://youtu.be/TUCn1mqSI6Q)

## Install and Config

```lua
-- with lazy.nvim
return {
  "LintaoAmons/bookmarks.nvim",
  -- pin the plugin at specific version for stability
  -- backup your bookmark sqlite db when there are breaking changes (major version change)
  tag = "v4.0.0",
  dependencies = {
    {"kkharji/sqlite.lua"},
    -- picker backend (choose one):
    {"folke/snacks.nvim"},              -- default picker backend
    -- {"nvim-telescope/telescope.nvim"}, -- set picker.picker_backend = "telescope" to use
  },
  config = function()
    local opts = {} -- check the "./lua/bookmarks/default-config.lua" file for all the options
    require("bookmarks").setup(opts) -- you must call setup to init sqlite db
  end,
}

-- run :BookmarksInfo to see the running status of the plugin
```

### Picker Backend

The default picker backend is **snacks.nvim**. To use telescope instead:

```lua
require("bookmarks").setup({
  picker = {
    picker_backend = "telescope", -- "snacks" (default) or "telescope"
  },
})
```

> Check the [default-config.lua](./lua/bookmarks/default-config.lua) file for all the configuration options.

> For Windows users, if you encounter sqlite dependency issues, please refer to https://github.com/LintaoAmons/bookmarks.nvim/issues/73 for potential solutions.

## Usage

### Basic Bookmark Operations

| Command         | Description                                                                                                                         |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `BookmarksMark` | Mark current line into active BookmarkList. Rename existing bookmark under cursor. Toggle it off if the new name is an empty string |
| `BookmarksGoto` | Go to bookmark at current active BookmarkList                                                                                       |
| `BookmarksNewList` | Create a new bookmark list, but I normally use `BookmarksTree` to create new list |
| `BookmarksLists`   | Pick a bookmark list                                                              |
| `BookmarksCommands`        | Find bookmark commands and trigger it                    |

> [!NOTE]
> These shortcuts are available in the picker (both snacks and telescope)

| Shortcut | Action for bookmarks                       | Action for lists                 |
| -------- | ------------------------------------------ | -------------------------------- |
| `Enter`  | Go to selected bookmark                    | set selected list as active list |
| `<C-d>`  | Delete selected bookmark                   | Delete selected list             |

and you can bind the commands to a shortcut or create a custom command out of it.

```lua
-- call built-in commands directly
vim.keymap.set({ "n", "v" }, "Bd", function()
  require("bookmarks.commands")["Delete marks of current file"]()
end, { desc = "Bookmark Clear Line" })

-- or create your custom commands
vim.api.nvim_create_user_command("BookmarksClearCurrentFile", function()
  require("bookmarks.commands")["Delete marks of current file"]()
end, {})
```

You can find all the built-in command names in [commands/init.lua](https://github.com/LintaoAmons/bookmarks.nvim/blob/main/lua/bookmarks/commands/init.lua).

You can also extend the plugin by creating your own custom commands and put them into the config:

```lua
require("bookmarks").setup({
  commands = {
    ["Mark warning"] = function()
      vim.ui.input({ prompt = "[Warn Bookmark]" }, function(input)
        if input then
          local Service = require("bookmarks.domain.service")
          Service.toggle_mark("⚠ " .. input)
          require("bookmarks.sign").safe_refresh_signs()
        end
      end)
    end,
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
-- Default keybindings in the treeview buffer with the new format
keymap = {
  ["q"] = {
    action = "quit",
    desc = "Close the tree view window"
  },
  -- ... See more in the default-config.lua
  ["+"] = {
    action = "add_to_aider",
    desc = "Add to Aider"
  },
  -- Example of a custom mapping
  ["<C-o>"] = {
    ---@type Bookmarks.KeymapCustomAction
    action = function(node, info)
      if info.type == 'bookmark' then
        vim.system({'open', info.dirname}, { text = true })
      end
    end,
    desc = "Open the current node with system default software",
  },
}
```

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

### More commands

| Command            | Description                                                                       |
| ------------------ | --------------------------------------------------------------------------------- |
| `BookmarksDesc`    | Add description to the bookmark under cursor, if no bookmark, then mark it first  |
| `BookmarksGrep`    | Grep through the content of all bookmarked files                                  |
| `BookmarksInfo`    | Overview plugin current status                                                    |
| `BookmarksInfoCurrentBookmark` | Show current bookmark info                                            |
| `BookmarkRebindOrphanNode` | Rebind orphaned nodes by attaching them to the root node          |

### Keymap

This plugin doesn't provide any default keybinding. I recommend you to have these keybindings.

```lua
vim.keymap.set({ "n", "v" }, "mm", "<cmd>BookmarksMark<cr>", { desc = "Mark current line into active BookmarkList." })
vim.keymap.set({ "n", "v" }, "mo", "<cmd>BookmarksGoto<cr>", { desc = "Go to bookmark at current active BookmarkList" })
vim.keymap.set({ "n", "v" }, "ma", "<cmd>BookmarksCommands<cr>", { desc = "Find and trigger a bookmark command." })
vim.keymap.set({ "n", "v" }, "md", "<cmd>BookmarksDesc<cr>", { desc = "Add description to bookmark under cursor." })
```

## Advanced Usage

In this section, we will cover advanced usage of the bookmarks.nvim plugin, focusing on customization and programmatic interaction.

Check the [ADVANCED_USAGE.md](./ADVANCED_USAGE.md) for more detailed information on advanced configurations and usage.

## CONTRIBUTING

Don't hesitate to ask me anything about the codebase if you want to contribute.

Goto [help-wanted issues](https://github.com/LintaoAmons/bookmarks.nvim/issues?q=state:open%20label:%22help%20wanted%22) to check the task you can help with.

Most of them should have some hints about how we want to impl it.

- Plugin Structure:
  1. `plugin/bookmarks.lua` the entry point of the plugin
  2. `lua/bookmarks/domain` where the main objects/concepts live

## Self-Promotion

- [my website](https://oatnil.top)
- [my neovim config](https://github.com/LintaoAmons/VimEverywhere/tree/main/nvim)
- [scratch.nvim](https://github.com/LintaoAmons/scratch.nvim)
- [cd-project.nvim](https://github.com/LintaoAmons/cd-project.nvim)
- [bookmarks.nvim](https://github.com/LintaoAmons/bookmarks.nvim)
- [context-menu.nvim](https://github.com/LintaoAmons/context-menu.nvim)

<a href="https://www.buymeacoffee.com/lintaoamond" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
