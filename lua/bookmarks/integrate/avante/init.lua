local M = {}

function M.ask_avante_with_active_list()
  local Repo = require("bookmarks.domain.repo")
  local list_node = Repo.ensure_and_get_active_list()
  local Node = require("bookmarks.domain.node")
  local bookmarks = Node.get_all_bookmarks(list_node)
  local filepaths = {}
  local uv = vim.loop
  for _, b in ipairs(bookmarks) do
    local filepath = b.location.path
    if filepath and uv.fs_stat(filepath) then
      table.insert(filepaths, filepath)
    end
  end

  require("avante.api").ask()
  for _, filepath in ipairs(filepaths) do
    require("avante").get().file_selector:add_selected_file(filepath)
  end
end

return M
