---Get the current version of the project
---@return string|nil version The git commit hash or nil if error
local function get_current_version()
  -- Check if git command exists
  local has_git = vim.fn.executable("git") == 1
  if not has_git then
    return nil
  end

  -- Execute git command and capture both output and error
  local output = vim.fn.system("git rev-parse --short HEAD")
  local exit_code = vim.v.shell_error

  if exit_code ~= 0 then
    return nil
  end

  -- Clean up the output by removing newline
  local version = output:gsub("\n", "")
  return version
end

---Trim leading and trailing whitespace from a string
---@param str string
---@return string
local function trim(str)
  return str:gsub("^%s+", ""):gsub("%s+$", "")
end

---@param file_path string
---@return string
local function shorten_file_path(file_path)
  local parts = {}

  file_path = file_path:gsub(vim.fn.expand("$HOME"), "~")
  for part in string.gmatch(file_path, "[^/]+") do
    table.insert(parts, part)
  end

  if #parts <= 1 then
    return file_path -- If there's only one part, return the original path
  end

  local filename = table.remove(parts) -- Remove and get the last part (filename)
  local shorten = vim.tbl_map(function(part)
    return string.sub(part, 1, 1)
  end, parts)

  return table.concat(shorten, "/") .. "/" .. filename
end

---Deep copy a table
---@param original any
---@return any
local function deep_copy(original)
  if type(original) ~= "table" then
    return original
  end

  local copy = {}
  for key, value in pairs(original) do
    copy[deep_copy(key)] = deep_copy(value)
  end

  return copy
end

---@param msg string
---@param level? integer
local function log(msg, level)
  vim.notify(msg, level or vim.log.levels.ERROR, { title = "easy-commands.nvim" })
end

---@param path string
---@return boolean
local function contains_marker_file(path)
  local marker_files = { ".git", ".gitignore" } -- list of marker files
  for _, file in ipairs(marker_files) do
    local full_path = path .. "/" .. file
    if vim.fn.filereadable(full_path) == 1 or vim.fn.isdirectory(full_path) == 1 then
      return true
    end
  end
  return false
end

---@param path string
---@return boolean
local function is_homedir(path)
  local home_dir = vim.loop.os_homedir()
  return path == home_dir
end

---Find the project path by traversing up the directory tree
---@return string|nil
local function find_project_path()
  for i = 1, 30, 1 do
    local dir = vim.fn.expand("%:p" .. string.rep(":h", i))
    if contains_marker_file(dir) then
      return dir
    end
    if is_homedir(dir) then
      return nil
    end
  end
  return nil
end

---Find the project name by traversing up the directory tree
---@return string
local function find_project_name()
  local project_path = find_project_path()
  if project_path then
    return vim.fn.fnamemodify(project_path, ":t")
  end
  return ""
end

---Get the relative path of the current buffer
---@return string
local function get_buf_relative_path()
  local buf_path = vim.fn.expand("%:p")
  local project_path = find_project_path() or ""
  return string.sub(buf_path, string.len(project_path) + 2, string.len(buf_path))
end

-- Function to generate an ID in the datetime format
---@return string
local function generate_datetime_id()
  -- Get the current date and time in the desired format
  local datetime = os.date("%Y%m%d%H%M%S")

  -- Generate a random number (e.g., using math.random) and append it to the datetime
  local random_suffix = ""
  for _ = 1, 8 do
    random_suffix = random_suffix .. tostring(math.random(0, 9))
  end

  -- Concatenate the datetime and random suffix to create the ID
  local id = datetime .. random_suffix

  return id
end

return {
  trim = trim,
  shorten_file_path = shorten_file_path,
  get_current_version = get_current_version,
  deep_copy = deep_copy,
  find_project_path = find_project_path,
  find_project_name = find_project_name,
  get_buf_relative_path = get_buf_relative_path,
  log = log,
  generate_datetime_id = generate_datetime_id,
}
