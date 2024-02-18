> v0.2.0 breaking change: add visitedAt to Bookmark structure

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

## Commands and Apis

There's two concepts in this plugin: `BookmarkList` and `Bookmark`. You can look into the code to find the structure of those two domain objects

| Command                           | Description                                               |
|-----------------------------------|-----------------------------------------------------------|
| `BookmarksMark`                   | mark current line into active BookmarkList                |
| `BookmarksGoto`                   | go to bookmark at current active BookmarkList             |
| `BookmarksMarkToList`             | mark current line and put it into a specific BookmarkList |
| `BookmarksMarkGotoBookmarkInList` | go to bookmark at specific BookmarkList                   |
| `BookmarksGotoRecent`             | go to lastest visited/created Bookmark                    |
| `BookmarksAddList`                | add a new BookmarkList and set it as active               |
| `BookmarksSetActiveList`          | set a BookmarkList as active                              |

APIs:

https://github.com/LintaoAmons/bookmarks.nvim/blob/32053ab797cdfb2bc53388bc4b8a82f7aaf0a3b5/lua/bookmarks/api.lua#L97-L101

This plugin don't provide any default keybinding. But for your reference, here's my personal nvim config. I have only 3 keybindings for bookmarks, the rest will only be triggered by search the commands

https://github.com/LintaoAmons/CoolStuffes/blob/1fdfa7e7776aacc7d2447934a29bdf76b5020b10/lazyvim/.config/nvim/lua/config/keymaps.lua#L9-L11

## Thanks

- [Lspsaga: for the sign related code](https://github.com/nvimdev/lspsaga.nvim)

## FIND MORE USER FRIENDLY PLUGINS MADE BY ME

- [scratch.nvim](https://githqb.com/LintaoAmons/scratch.nvim)
- [easy-commands.nvim](https://github.com/LintaoAmons/easy-commands.nvim)
- [cd-project.nvim](https://github.com/LintaoAmons/cd-project.nvim)
- [bookmarks.nvim](https://github.com/LintaoAmons/bookmarks.nvim)
- [plugin-template.nvim](https://github.com/LintaoAmons/plugin-template.nvim)

## TODO

- [ ] BookmarksMark's input box as a command line. Text start with `!` considered as command.
  - [ ] `!newlist [listname]` bookmark current line into a newly created bookmark list and set the list as current active list.
- [ ] Enhance gotoBookmarks: if the prompt didn't match any bookmarks in current active bookmarklist, it will try to search among all bookmarks
- [ ] more useful information when deal with corrupted json db
- [ ] delete bookmark when browsing in telescope
- [ ] rename bookmark in telescope
- [ ] Recent files as bookmarks: record all the buffer the user recently opened and sort by the visitedAt 
- [x] A new command to create bookmark and put it into specific bookmark list (instead current active one)
- [ ] goto next/prev bookmark
- [ ] switch to another bookmark list in telescope or switch to display all bookmarks in telescope
