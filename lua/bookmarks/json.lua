---@param tbl table
---@param path string
local write_json_file = function(tbl, path)
  local content = vim.fn.json_encode(tbl) -- Encoding table to JSON string

  local formatter = "jq"
  if not (0 == vim.fn.executable(formatter)) then
    local fmt_cmd = { formatter, "--sort-keys", "--monochrome-output" }
    local result = vim.system(fmt_cmd, { stdin = content }):wait()
    if result.code ~= 0 then
      error("Failed to format JSON with " .. formatter .. ": " .. result.stderr)
      return nil
    end
    content = result.stdout
  end

  local file, err = io.open(path, "w")
  if not file then
    error("Could not open file: " .. err)
    return nil
  end

  file:write(content)
  file:close()
end

---@param path string
---@return table
local read_or_init_json_file = function(path)
  local file, _ = io.open(path, "r")
  if not file then
    write_json_file({}, path)
    return {}
  end

  local content = file:read("*a") -- Read the entire content
  file:close()

  return vim.fn.json_decode(content) or {}
end

return {
  write_json_file = write_json_file,
  read_or_init_json_file = read_or_init_json_file,
}
