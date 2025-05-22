local M = {}

--- Add bookmarked files into aider
--- @param node Bookmarks.Node The bookmark node to process
--- @param opts? {read_only: boolean} with optional settings, e.g.,
function M.add(node, opts)
  opts = opts or {}
  local read_only = opts.read_only or false

  -- Check if nvim_aider is available
  local ok, _ = pcall(require, "nvim_aider.terminal")
  if not ok then
    vim.notify("Aider integration not found. Please ensure nvim_aider is installed.", vim.log.levels.ERROR)
    return
  end

  local _, terminal = pcall(require, "nvim_aider.terminal")
  local _, commands = pcall(require, "nvim_aider.commands_slash")

  -- Get all bookmarks from the node
  local bookmarks = require("bookmarks.domain.node").get_all_bookmarks(node)

  -- Collect file paths
  local filePaths = {}
  for _, bookmark in ipairs(bookmarks) do
    if bookmark.location and bookmark.location.path then
      table.insert(filePaths, bookmark.location.path)
    end
  end

  -- Use nvim_aider API to add files
  if #filePaths > 0 then
    if read_only then
      terminal.command(commands["read-only"].value, table.concat(filePaths, " "))
    else
      terminal.command(commands.add.value, table.concat(filePaths, " "))
    end
  end

  vim.notify("Added " .. #filePaths .. " bookmarked files to Aider", vim.log.levels.INFO)
end

--- Drop bookmarked files from aider
--- @param node Bookmarks.Node The bookmark node to process
function M.drop(node)
  -- Check if nvim_aider is available
  local ok, _ = pcall(require, "nvim_aider.terminal")
  if not ok then
    vim.notify("Aider integration not found. Please ensure nvim_aider is installed.", vim.log.levels.ERROR)
    return
  end

  local _, terminal = pcall(require, "nvim_aider.terminal")
  local _, commands = pcall(require, "nvim_aider.commands_slash")

  -- Get all bookmarks from the node
  local bookmarks = require("bookmarks.domain.node").get_all_bookmarks(node)

  -- Collect file paths
  local filePaths = {}
  for _, bookmark in ipairs(bookmarks) do
    if bookmark.location and bookmark.location.path then
      table.insert(filePaths, bookmark.location.path)
    end
  end

  -- Use nvim_aider API to drop files
  if #filePaths > 0 then
    terminal.command(commands.drop.value, table.concat(filePaths, " "))
  end

  vim.notify("Dropped " .. #filePaths .. " bookmarked files from Aider", vim.log.levels.INFO)
end

return M
