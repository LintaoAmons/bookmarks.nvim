local Repo = require("bookmarks.domain.repo")
local ok, codecompanion = pcall(require, "codecompanion.config")
if not ok then
  return
end

local M = {}

---@class Bookmarks.CodeCompanionPromptReference
---@field type string The type of reference (file/symbols/url)
---@field path? string|string[] Path to the file or files
---@field url? string URL for web references

---ask codecompanion with a bookmark list as references
---@param list Bookmarks.Node
---@return Bookmarks.CodeCompanionPromptReference[]
local function build_references(list)
  local references = {}
  local seen_paths = {}

  -- Recursive function to process nodes
  local function process_node(node)
    if node.type == "bookmark" and node.location then
      -- Only add unique file paths
      if not seen_paths[node.location.path] then
        seen_paths[node.location.path] = true
        table.insert(references, {
          type = "file",
          path = node.location.path,
        })
      end
    end

    -- Process children if it's a list
    if node.type == "list" and node.children then
      for _, child in ipairs(node.children) do
        process_node(child)
      end
    end
  end

  -- Start processing from the root node
  process_node(list)

  Snacks.debug.log(references)
  return references
end

---ask codecompanion with a bookmark list as references
---@param list Bookmarks.Node | nil The list of bookmarks to process. Use active list if nil
---@return nil
function M.ask_with_list_as_reference(list)
  list = list or Repo.ensure_and_get_active_list()
  Snacks.debug.log(codecompanion)
  codecompanion.register_prompt("ask_with_list_as_reference", {
    strategy = "chat",
    description = "Ask a question about the provided list of files",
    opts = {
      index = 11,
      is_default = true,
      is_slash_cmd = false,
      short_name = "ref",
      auto_submit = false,
    },
    references = build_references(list),
    prompts = {
      {
        role = "user",
        content = "I have shared several files with you. Please analyze them and answer my questions about their content and structure.",
        opts = {
          contains_code = false,
        },
      },
    },
  })
end

function M.setup()
  local config = vim.g.bookmarks_config
  if not config.codecompanion.enabled then
    return
  end

  M.ask_with_list_as_reference()
end

return M
