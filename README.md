# Bookmarks.nvim

You only need one shortcut to add bookmarks.

- Toggle mark: Add, Rename and Remove mark with only one shortcut
- Mark with name: so you can record more information
- Icon and virtual text: display icon and name at the marked lines
- Group your bookmarks: so keep you away from the noises
- Persistent your bookmarks into a human reable json file, which you can manipulate munally
- [More usecases](./usecases.md)
- [Video Explaination](https://www.youtube.com/watch?v=M6fncKXYw_Y)

![show](https://github.com/LintaoAmons/bookmarks.nvim/assets/95092244/82ff1c66-d8ee-4e0b-a1de-b6473ec4aa33)

## Install and Config

- Simple version: everything should work out of box if you are ok with the default config.

```lua
-- with lazy.nvim
return {
  "LintaoAmons/bookmarks.nvim",
  tag = "v0.5.3", -- optional, pin the plugin at specific version for stability
  dependencies = {
    {"nvim-telescope/telescope.nvim"},
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
      signs = {
        mark = { icon = "", color = "grey" },
      },
      hooks = {
        {
          ---a sample hook that change the working directory when goto bookmark
          ---@param bookmark Bookmarks.Bookmark
          ---@param projects Bookmarks.Project[]
          callback = function(bookmark, projects)
            local project_path
            for _, p in ipairs(projects) do
              if p.name == bookmark.location.project_name then
                project_path = p.path
              end
            end
            if project_path then
              vim.cmd("cd " .. project_path)
            end
          end,
        },
      },
    })
  end
}
```

</details>

## Commands and Keybindings

There's two concepts in this plugin: `BookmarkList` and `Bookmark`.

You can look into the code to find the structure of those two domain objects

| Command                 | Description                                                                                                                         |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `BookmarksMark`         | Mark current line into active BookmarkList. Rename existing bookmark under cursor. Toggle it off if the new name is an empty string |
| `BookmarksGoto`         | Go to bookmark at current active BookmarkList                                                                                       |
| `BookmarksCommands`     | Find and trigger a bookmark command.                                                                                                |
| `BookmarksGotoRecent`   | Go to latest visited/created Bookmark                                                                                               |
| `BookmarksReload`       | Clean the cache and resync the bookmarks jsonfile                                                                                   |
| `BookmarksEditJsonFile` | An shortcut to edit bookmark jsonfile, remember BookmarksReload to clean the cache after you finish editing                         |

<details>
<summary>BookmarksCommands(subcommands) we have right now</summary>

> just because I don't know how to write Telescope extension, so I somehow do it this way.

| Command                   | Description                                                                                 |
| ------------------------- | ------------------------------------------------------------------------------------------- |
| [List] new                | create a new BookmarkList and set it to active and mark current line into this BookmarkList |
| [List] rename             | rename a BookmarkList                                                                       |
| [List] delete             | delete a bookmark list                                                                      |
| [List] set active         | set a BookmarkList as active                                                                |
| [List] Browsing all lists |                                                                                             |
| [Mark] mark to list       | bookmark current line and add it to specific bookmark list                                  |
| [Mark] rename bookmark    | rename selected bookmark                                                                    |
| [Mark] Browsing all marks |                                                                                             |
| [Mark] delete bookmark    | delete selected bookmarks                                                                   |

</details>

This plugin don't provide any default keybinding. I recommend you to have those three keybindings.

```lua
vim.keymap.set({ "n", "v" }, "mm", "<cmd>BookmarksMark<cr>", { desc = "Mark current line into active BookmarkList." })
vim.keymap.set({ "n", "v" }, "mo", "<cmd>BookmarksGoto<cr>", { desc = "Go to bookmark at current active BookmarkList" })
vim.keymap.set({ "n", "v" }, "ma", "<cmd>BookmarksCommands<cr>", { desc = "Find and trigger a bookmark command." })
vim.keymap.set({ "n", "v" }, "mg", "<cmd>BookmarksGotoRecent<cr>", { desc = "Go to latest visited/created Bookmark" })
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
- [x] more useful information when deal with corrupted json db (no issues report yet)
- [ ] refactor: extract picker module
- [x] telescope enhancement (use specific command instead)
- [x] A new command to create bookmark and put it into specific bookmark list (instead current active one)
- [x] Project
    - [x] Add a project field
    - [x] relative path. (project_path/relative_path can make the bookmarks portable, share your bookmarks to another people or your second laptop)
    - [ ] bookmarks of current project
    - [ ] Hooks: Gotobookmark can trigger function like switch project automatically
- [ ] Grep content in bookmarks' files

### V2

- [ ] Sequance diagram out of bookmarks: Pattern `[actor] -->actor sequance_number :: desc`
- [ ] filetree-like BookmarkList and Bookmark browsing.
    - use `nui` or a `custom buffer`
    - custom buffer (can render more things, and can nav/copy/paste with ease)
        - local Keybindings
        - popup window
        - readonly and read current line to trigger action
- [ ] Recent files as bookmarks: record all the buffer the user recently opened and sort by the visited_at
- [ ] goto next/prev bookmark in the current buffer
- [ ] smart location calibration according to bookmark content
