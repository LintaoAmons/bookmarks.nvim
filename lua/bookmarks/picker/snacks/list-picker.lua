local Repo = require("bookmarks.domain.repo")
local Service = require("bookmarks.domain.service")

local M = {}

---@param callback fun(list: Bookmarks.Node): nil
---@param opts? {prompt?: string}
function M.pick_bookmark_list(callback, opts)
  opts = opts or {}

  local function start_picker()
    local lists = Repo.find_lists()
    local items = {}
    for _, list in ipairs(lists) do
      table.insert(items, {
        text = list.name,
        list = list,
      })
    end

    Snacks.picker({
      title = opts.prompt or "Bookmark Lists",
      items = items,
      format = "text",
      preview = "none",
      layout = { preview = false },
      confirm = function(picker, item)
        picker:close()
        if item then
          callback(item.list)
        end
      end,
      actions = {
        delete_list = function(picker, item)
          if not item or not item.list then
            return
          end
          Service.delete_node(item.list.id)
          picker:close()
          vim.schedule(function()
            start_picker()
          end)
        end,
      },
      win = {
        input = {
          keys = {
            ["<C-d>"] = { "delete_list", mode = { "i", "n" }, desc = "Delete list" },
          },
        },
      },
    })
  end

  start_picker()
end

return M
