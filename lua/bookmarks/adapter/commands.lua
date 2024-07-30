local repo = require("bookmarks.repo")
local api = require("bookmarks.api")
local picker = require("bookmarks.adapter.picker")
local utils = require("bookmarks.utils")
local domain = require("bookmarks.domain")

---@class Bookmark.Command
---@field name string
---@field callback fun(): nil
---@field description? string

-- TODO: a helper function to generate this structure to markdown table to put into README file

---@type Bookmark.Command[]
local commands = {

  {
    name = "[List] new",
    callback = function()
      vim.ui.input({ prompt = "Enter the name of the new list: " }, function(input)
        if not input then
          return
        end
        local name = vim.trim(input) ~= "" and input or tostring(os.time())
        local newlist = api.add_list({ name = name })
        api.mark({ name = "", list_name = newlist.name })
      end)
    end,
    description = "create a new BookmarkList and set it to active and mark current line into this BookmarkList",
  },
  {
    name = "[List] rename",
    callback = function()
      picker.pick_bookmark_list(function(bookmark_list)
        vim.ui.input({ prompt = "Enter new name: " }, function(input)
          if not input then
            return
          end
          api.rename_bookmark_list(input, bookmark_list.name)
          utils.log("bookmark_list renamed from: " .. bookmark_list.name .. " to " .. input, vim.log.levels.INFO)
        end)
      end)
    end,
    description = "rename a BookmarkList",
  },
  {
    name = "[List] delete",
    callback = function()
      local bookmark_lists = repo.bookmark_list.read.find_all()

      vim.ui.select(bookmark_lists, {
        prompt = "Select the bookmark list you want to delete",
        format_item = function(item)
          ---@cast item Bookmarks.BookmarkList
          return item.name
        end,
      }, function(choice)
        ---@cast choice Bookmarks.BookmarkList
        if not choice then
          return
        end
        vim.ui.input({ prompt = "Are you sure you want to delete list" .. choice.name .. "? Y/N" }, function(input)
          if input == "Y" then
            repo.bookmark_list.write.delete(choice.name)
            vim.notify(choice.name .. " list deleted")
          else
            vim.notify("deletion abort")
            return
          end
        end)
      end)
    end,
    description = "delete a bookmark list",
  },
  {
    name = "[List] set active",
    callback = function()
      picker.pick_bookmark_list(function(bookmark_list)
        api.set_active_list(bookmark_list.name)
        picker.pick_bookmark(function(bookmark)
          api.goto_bookmark(bookmark)
        end)
      end)
    end,
    description = "set a BookmarkList as active",
  },
  {
    name = "[List] Browsing all lists",
    callback = function()
      picker.pick_bookmark_list(function(bookmark_list)
        picker.pick_bookmark(function(bookmark)
          api.goto_bookmark(bookmark, { open_method = "vsplit" })
        end, { bookmark_list = bookmark_list })
      end)
    end,
    description = "",
  },
  {
    name = "[Mark] mark to list",
    callback = function()
      picker.pick_bookmark_list(function(choice)
        api.mark({
          name = "", -- TODO: ask user to input name?
          list_name = choice.name,
        })
      end)
    end,
    description = "bookmark current line and add it to specific bookmark list",
  },
  {
    name = "[Mark] rename bookmark",
    callback = function()
      picker.pick_bookmark(function(bookmark)
        vim.ui.input({ prompt = "New name of the bookmark" }, function(input)
          if input then
            api.rename_bookmark(bookmark.id, input or "")
          end
        end)
      end)
    end,
    description = "rename selected bookmark",
  },
  {
    name = "[Mark] Browsing all marks",
    callback = function()
      picker.pick_bookmark(function(bookmark)
        api.goto_bookmark(bookmark, { open_method = "vsplit" })
      end, { all = true })
    end,
    description = "",
  },
  {
    name = "[Mark] Bookmarks of current project",
    callback = function()
      picker.pick_bookmark_of_current_project(function(bookmark)
        api.goto_bookmark(bookmark, { open_method = "vsplit" })
      end, { all = true })
    end,
    description = "",
  },
  {
    name = "[Mark] grep the marked files",
    callback = function()
      local ok, fzf_lua = pcall(require, "fzf-lua")
      if not ok then
        return utils.log("this command requires fzf-lua plugin", vim.log.levels.ERROR)
      end

      local opts = {}
      opts.prompt = "rg> "
      opts.git_icons = true
      opts.file_icons = true
      opts.color_icons = true
      -- setup default actions for edit, quickfix, etc
      opts.actions = fzf_lua.defaults.actions.files
      opts.fzf_opts = { ["--layout"] = "reverse-list" }
      -- see preview overview for more info on previewers
      opts.previewer = "builtin"
      opts.winopts = {
        split = "belowright new",
      }
      opts.fn_transform = function(x)
        return fzf_lua.make_entry.file(x, opts)
      end

      local list = repo.bookmark_list.write.find_or_set_active()
      local bookmarks = list.bookmarks
      local projects = repo.project.findall()
      local filepathes = ""
      for _, b in ipairs(bookmarks) do
        local fullpath = domain.bookmark.fullpath(b, projects)
        filepathes = filepathes .. " " .. fullpath
      end

      fzf_lua.fzf_live("rg --column --color=always <query> " .. filepathes .. " 2>/dev/null", opts)
    end,
    description = "grep in all the files that contain bookmarks",
  },
  {
    name = "[Mark] delete bookmark",
    callback = function()
      picker.pick_bookmark(function(bookmark)
        repo.mark.write.delete(bookmark)
      end)
    end,
    description = "delete selected bookmarks",
  },
}

return {
  commands = commands,
}
