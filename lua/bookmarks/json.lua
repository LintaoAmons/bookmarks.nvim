local utils = require("bookmarks.utils")

---@param tbl table
---@param path string
local write_json_file = function(tbl, path)
  local content = vim.fn.json_encode(tbl) -- Encoding table to JSON string

  local formatter = "jq"
  if not (0 == vim.fn.executable(formatter)) then
    local fmt_cmd = { formatter, "--sort-keys", "--monochrome-output" }
    local result = vim.system(fmt_cmd, { stdin = content }):wait()
    if result.code ~= 0 then
      utils.log("Failed to format JSON with " .. formatter .. ": " .. result.stderr)
      return nil
    end
    content = result.stdout
  end

  local file, err = io.open(path, "w")
  if not file then
    utils.log("Could not open file: " .. err)
    return nil
  end

  file:write(content)
  file:close()
end

---@param path string
---@param init_content table
---@return table
local read_or_init_json_file = function(path, init_content)
  local file, _ = io.open(path, "r")
  if not file then
    write_json_file(init_content, path)
    return init_content
  end

  local content = file:read("*a") -- Read the entire content
  file:close()

  return vim.fn.json_decode(content) or {}
end

local function backup(path)
  local bookmarks = read_or_init_json_file(path, { projects = {}, bookmark_lists = {} })
  -- write_json_file(bookmarks, path .. os.date("%Y-%m-%d-%H-%M-%S", os.time()) .. ".backup")
  write_json_file(bookmarks, path .. ".backup")
end

return {
  write_json_file = write_json_file,
  read_or_init_json_file = read_or_init_json_file,
  backup = backup,
}
