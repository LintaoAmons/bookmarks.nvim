> v0.2.0 breaking change: add visited_at to Bookmark structure

# Bookmarks.nvim

You only need one shortcut to add bookmarks.

- Toggle mark: Add and Remove mark with one shortcut
- Mark with name: so you can record more information
- Icon and virtual text: display icon and name at the marked lines
- Group your bookmarks: so keep your away from the noises
- Persistent your bookmarks into a human reable json file, which you can manipulate munally
- [More usecases](./usecases.md)
- [Video Explaination](https://www.youtube.com/watch?v=M6fncKXYw_Y)

![show](https://github.com/LintaoAmons/bookmarks.nvim/assets/95092244/82ff1c66-d8ee-4e0b-a1de-b6473ec4aa33)

## Install and Config

- Simple version: everything should work out of box if you are ok with the default config.

```lua
-- with lazy.nvim
return {
  "LintaoAmons/bookmarks.nvim"
  dependencies = {
    {"stevearc/dressing.nvim"} -- optional: to have the same UI shown in the GIF
  }
}
```

<details>
<summary>Detailed config</summary>
  
Right now we have only one config options

```lua
return { "LintaoAmons/bookmarks.nvim",
  config = function ()
    require("bookmarks").setup( {
      json_db_path = vim.fs.normalize(vim.fn.stdpath("config") .. "/bookmarks.db.json"),
    })
  end
}
```

</details>

## Commands and Keybindings

There's two concepts in this plugin: `BookmarkList` and `Bookmark`. You can look into the code to find the structure of those two domain objects

| Command                           | Description                                                                                                 |
|-----------------------------------|-------------------------------------------------------------------------------------------------------------|
| `BookmarksMark`                   | Mark current line into active BookmarkList.                                                                 |
| `BookmarksGoto`                   | Go to bookmark at current active BookmarkList                                                               |
| `BookmarksCommands`               | Find and trigger a bookmark command.                                                                        |
| `BookmarksGotoRecent`             | Go to latest visited/created Bookmark                                                                       |

This plugin don't provide any default keybinding. I recommend you to have those three keybindings.

```lua
vim.keymap.set({ "n", "v" }, "mm", "<cmd>BookmarksMark<cr>", { desc = "Mark current line into active BookmarkList." })
vim.keymap.set({ "n", "v" }, "mo", "<cmd>BookmarksGoto<cr>", { desc = "Go to bookmark at current active BookmarkList" })
vim.keymap.set({ "n", "v" }, "ma", "<cmd>BookmarksCommands<cr>", { desc = "Find and trigger a bookmark command." })
```

## Thanks

- [Lspsaga: for the sign related code](https://github.com/nvimdev/lspsaga.nvim)

## CONTRIBUTING

Don't hesitate to ask me anything about the codebase if you want to contribute.

You can contact with me by drop me an email or [telegram](https://t.me/+ssgpiHyY9580ZWFl)

## FIND MORE USER FRIENDLY PLUGINS MADE BY ME

- [scratch.nvim](https://github.com/LintaoAmons/scratch.nvim)
- [easy-commands.nvim](https://github.com/LintaoAmons/easy-commands.nvim)
- [cd-project.nvim](https://github.com/LintaoAmons/cd-project.nvim)
- [bookmarks.nvim](https://github.com/LintaoAmons/bookmarks.nvim)
- [plugin-template.nvim](https://github.com/LintaoAmons/plugin-template.nvim)

## TODO

### V1

- [x] BookmarksMark's input box as a command line. Text start with `!` considered as command.
  - [x] `!newlist [listname]` bookmark current line into a newly created bookmark list and set the list as current active list.
- [x] remove parse commands, prefer BookmarkCommands instead
- [x] `BookmarkCommands` commands picker, a picker allow user to trigger any bookmark command.
- [ ] user defined commands
- [x] more useful information when deal with corrupted json db (no issues report yet)
- [ ] refactor: extract picker module
- [ ] Telescope as default picker and will fallback to vim.ui if don't have telescope dependencies
- [x] telescope enhancement (use specific command instead)
- [ ] Recent files as bookmarks: record all the buffer the user recently opened and sort by the visited_at 
- [x] A new command to create bookmark and put it into specific bookmark list (instead current active one)
- [ ] goto next/prev bookmark in the current buffer

### V2

- [ ] filetree-like BookmarkList and Bookmark browsing.
