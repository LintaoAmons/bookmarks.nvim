> v0.2.0 breaking change: add visitedAt to Bookmark structure

# Bookmarks.nvim

You only need one shortcut to add bookmarks.

- Toggle mark: Add and Remove mark with one shortcut
- Mark with name: so you can record more information
- Icon and virtual text: display icon and name at the marked lines
- Group your bookmarks: so keep your away from the noises
- [More usecases](./usecases.md)
- [Video Explaination](https://www.youtube.com/watch?v=M6fncKXYw_Y)

![show](https://github.com/LintaoAmons/bookmarks.nvim/assets/95092244/82ff1c66-d8ee-4e0b-a1de-b6473ec4aa33)

## Install and Config

- Simple version: everything should work out of box if you are ok with the default config.

```lua
-- with lazy.nvim
return { "LintaoAmons/bookmarks.nvim" }
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

| Command                  | Description                                 |
|--------------------------|---------------------------------------------|
| `BookmarksMark`          | mark current line into active BookmarkList  |
| `BookmarksGoto`          | go to selected bookmark                     |
| `BookmarksGotoRecent`    | go to lastest visited/created Bookmark      |
| `BookmarksAddList`       | add a new BookmarkList and set it as active |
| `BookmarksSetActiveList` | set a BookmarkList as active                |

https://github.com/LintaoAmons/bookmarks.nvim/blob/a72c4c1e30e88df744128b4d24efbf6f0e2b4570/lua/bookmarks/api.lua#L73-L75

## Thanks

- [Lspsaga: for the sign related code](https://github.com/nvimdev/lspsaga.nvim)

## FIND MORE USER FRIENDLY PLUGINS MADE BY ME

- [scratch.nvim](https://githqb.com/LintaoAmons/scratch.nvim)
- [easy-commands.nvim](https://github.com/LintaoAmons/easy-commands.nvim)
- [cd-project.nvim](https://github.com/LintaoAmons/cd-project.nvim)
- [bookmarks.nvim](https://github.com/LintaoAmons/bookmarks.nvim)
- [plugin-template.nvim](https://github.com/LintaoAmons/plugin-template.nvim)

## TODO

- [ ] Global bookmarks: No matter which one is the current active list, global bookmarks will always show up.
- [ ] A new command to create bookmark and put it into specific bookmark list (instead current active one)
- [ ] goto next/prev bookmark
