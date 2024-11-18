# Bookmarks.nvim

- Simple: Add, Rename and Remove bookmarks with only one command, less shortcuts more productivity.
- Persistent: save your bookmarks into a human readable json file, which you can manipulate manually.
- Accessible: Find your bookmark by telescope or Treeview with ease.
- Informative: mark with a description, so you can record more information.
- Visibility: display icon and name at the marked lines, and highlight marked lines.
- Groups: arrange your bookmarks in groups, so keep you away from noises.
- Portable: Easily share your bookmarks across devices or with others by modifying the project path in the JSON file.

![showcase](https://github.com/user-attachments/assets/e47327bb-7dce-43a5-9c74-aaeb58091648)

## Install and Config

- Simple version: everything should work out of the box if you are ok with the default config.

```lua
-- with lazy.nvim
return {
  "LintaoAmons/bookmarks.nvim",
  -- tag = "v0.5.4", -- optional, pin the plugin at specific version for stability
  dependencies = {
    {"nvim-telescope/telescope.nvim"},
    {"stevearc/dressing.nvim"} -- optional: to have the same UI shown in the GIF
  }
}
```

<details>
<summary>Detailed config</summary>

```lua
return {
  "LintaoAmons/bookmarks.nvim",
  -- recommand, pin the plugin at specific version for stability
  -- backup your db.json file when you want to upgrade the plugin
  tag = "v1.4.1", 
  dependencies = {
    { "nvim-telescope/telescope.nvim" },
    { "stevearc/dressing.nvim" }, -- optional: to have the same UI shown in the GIF
  },
  config = function()
    local opts = {
      -- where you want to put your bookmarks db file (a simple readable json file, which you can edit manually as well)
      json_db_path = vim.fs.normalize(vim.fn.stdpath("config") .. "/bookmarks.db.json"),
      -- This is how the sign looks.
      signs = {
        mark = { icon = "󰃁", color = "red", line_bg = "#572626" },
      },
      picker = {
        -- choose built-in sort logic by name: string, find all the sort logics in `bookmarks.adapter.sort-logic`
        -- or custom sort logic: function(bookmarks: Bookmarks.Bookmark[]): nil
        sort_by = "last_visited",
      },
      -- optional, backup the json db file when a new neovim session started and you try to mark a place
      -- you can find the file under the same folder
      enable_backup = true,
      -- optional, show the result of the calibration when you try to calibrate the bookmarks
      show_calibrate_result = true,
      -- optional, auto calibrate the current buffer when you enter it
      auto_calibrate_cur_buf = true,
      -- treeview options
      treeview = {
        bookmark_format = function(bookmark)
          if bookmark.name ~= "" then return bookmark.name else return "[No Name]" end
        end,
        keymap = {
          quit = { "q", "<ESC>" },
          refresh = "R",
          create_folder = "a",
          tree_cut = "x",
          tree_paste = "p",
          collapse = "o",
          delete = "d",
          active = "s",
          copy = "c",
        },
      },
      -- do whatever you like by hooks
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
    }
    require("bookmarks").setup(opts)
  end,
}
```

</details>

## Usage

There's two key concepts in this plugin: `BookmarkList` and `Bookmark`.

You can look into the code to find the structure of those two domain objects.

### Commands

| Command                 | Description                                                                                                                         |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `BookmarksMark`         | Mark current line into active BookmarkList. Rename existing bookmark under cursor. Toggle it off if the new name is an empty string |
| `BookmarksGoto`         | Go to bookmark at current active BookmarkList                                                                                       |
| `BookmarksCommands`     | Find and trigger a bookmark command.                                                                                                |
| `BookmarksGotoRecent`   | Go to latest visited/created Bookmark                                                                                               |
| `BookmarksEditJsonFile` | An shortcut to edit bookmark jsonfile                                                                                               |
| `BookmarksTree`         | Display all bookmarks with tree-view, and use "cut", "paste", "create folder" to edit the tree.                                     |

<details>
<summary>BookmarksCommands(subcommands) we have right now</summary>

> just because I don't know how to write Telescope extension, so I somehow do it this way.

| Command                             | Description                                                                                 |
| ----------------------------------- | ------------------------------------------------------------------------------------------- |
| [List] new                          | create a new BookmarkList and set it to active and mark current line into this BookmarkList |
| [List] rename                       | rename a BookmarkList                                                                       |
| [List] delete                       | delete a bookmark list                                                                      |
| [List] set active                   | set a BookmarkList as active                                                                |
| [List] Browsing all lists           |                                                                                             |
| [Mark] mark to list                 | bookmark current line and add it to specific bookmark list                                  |
| [Mark] rename bookmark              | rename selected bookmark                                                                    |
| [Mark] Browsing all marks           |                                                                                             |
| [Mark] Bookmarks of current project |                                                                                             |
| [Mark] grep the marked files        | grep in all the files that contain bookmarks                                                |
| [Mark] delete bookmark              | delete selected bookmarks                                                                   |

Also if you want to bind a shortcut to those commands, you can do it by writing some code....

```lua
local function call_bookmark_command()
	local commands = require("bookmarks.adapter.commands").commands
	local command
	for _, c in ipairs(commands) do
		if c.name == "[Mark] Bookmarks of current project" then -- change it to one of the command above
			command = c
		end
	end

	if command then
		command.callback()
	end
end

vim.keymap.set("n", "<leader>ll", call_bookmark_command)
```

</details>

### BookmarksTree

Check the tree section in the config to find out all the actions you can use.

### Keymap

This plugin doesn't provide any default keybinding. I recommend you to have these four keybindings.

```lua
vim.keymap.set({ "n", "v" }, "mm", "<cmd>BookmarksMark<cr>", { desc = "Mark current line into active BookmarkList." })
vim.keymap.set({ "n", "v" }, "mo", "<cmd>BookmarksGoto<cr>", { desc = "Go to bookmark at current active BookmarkList" })
vim.keymap.set({ "n", "v" }, "ma", "<cmd>BookmarksCommands<cr>", { desc = "Find and trigger a bookmark command." })
vim.keymap.set({ "n", "v" }, "mg", "<cmd>BookmarksGotoRecent<cr>", { desc = "Go to latest visited/created Bookmark" })
```

## CONTRIBUTING

Don't hesitate to ask me anything about the codebase if you want to contribute.

By [telegram](https://t.me/+ssgpiHyY9580ZWFl) or [微信: CateFat](https://lintao-index.pages.dev/assets/images/wechat-437d6c12efa9f89bab63c7fe07ce1927.png)

- How to get started:
  1. `plugin/bookmarks.lua` the entry point of the plugin
  2. `lua/bookmarks/domain` where the main objects/concepts live
  3. code layers: user --> `lua/bookmarks/adapter` --> `lua/bookmarks/api` --> `lua/bookmarks/repo` --> json db

## Some Other Neovim Stuff

- [my neovim config](https://github.com/LintaoAmons/CoolStuffes/tree/main/nvim/.config/nvim)
- [scratch.nvim](https://github.com/LintaoAmons/scratch.nvim)
- [cd-project.nvim](https://github.com/LintaoAmons/cd-project.nvim)
- [bookmarks.nvim](https://github.com/LintaoAmons/bookmarks.nvim)
- [context-menu.nvim](https://github.com/LintaoAmons/context-menu.nvim)

## TODO

### V1

- [x] BookmarksMark's input box as a command line. Text start with `!` considered as command.
  - [x] `!newlist [listname]` bookmark current line into a newly created bookmark list and set the list as current active list.
- [x] remove parse commands, prefer BookmarkCommands instead
- [x] `BookmarkCommands` commands picker, a picker allow user to trigger any bookmark command.
- [x] more useful information when dealing with corrupted json db (no issues report yet)
- [x] telescope enhancement (use specific command instead)
- [x] A new command to create bookmark and put it into specific bookmark list (instead current active one)
- [x] Project
  - [x] Add a project field
  - [x] relative path. (project_path/relative_path can make the bookmarks portable, share your bookmarks to another people or your second laptop)
  - [x] bookmarks of current project
  - [x] Hooks: Gotobookmark can trigger function like switch project automatically
- [x] Grep content in files that contains bookmarks

### V2

- [ ] picker
  - [ ] refactor: extract picker module and remove unused modules
  - [ ] get bookmarks in active list --> filter --> sort --> telescope/fzflua
- [ ] filetree-like BookmarkList and Bookmark browsing.
  - [x] MVP thx! @shanlihou
  - [ ] action alias or rename some of the actions to make it more readable for users
  - [ ] bookmark filter
  - [ ] Add top level bookmark list
  - [ ] sort/modify by bookmark.order field
  - [ ] floating preview window
  - [ ] better default bookmark render format(string format, then better UI)
  - [ ] `u` undo. Expecially for unexpected `d` delete
- [x] ~Recent files as bookmarks: record all the buffer the user recently opened and sort by the visited_at~
  - just use `smart-open.nvim`
- [ ] goto next/prev bookmark in the current buffer
- [ ] smart location calibration according to bookmark content
  - [x] Init and calibrate by full match of the line content
  - [ ] A match algorithm that can tolerate small changes of the line content 
- [ ] auto generate bookmark name by AI (Sent request to openai api, etc)

### V3

- [ ] Sequance diagram out of bookmarks: Pattern `[actor] -->actor sequance_number :: desc`
