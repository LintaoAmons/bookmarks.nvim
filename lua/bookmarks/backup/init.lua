local M = {}
local fn = vim.fn
local uv = vim.loop

---Get backup directory path from config or fallback
---@param backup_dir? string
---@return string
local function get_backup_dir(backup_dir)
  if not backup_dir then
    return fn.stdpath("data") .. "/bookmarks.backup"
  end
  return backup_dir
end
M.get_backup_dir = get_backup_dir

---Create backup directory if it doesn't exist
---@param dir string
local function ensure_backup_dir(dir)
  if fn.isdirectory(dir) == 0 then
    local ok = fn.mkdir(dir, "p")
    if ok == 0 then
      error(string.format("Failed to create backup directory: %s", dir))
    end
  end
end

---@param src string Source file path
---@param dst string Destination file path
local function copy_file(src, dst)
  local source = uv.fs_open(src, "r", 438)
  if not source then
    error(string.format("Failed to open source file: %s", src))
    return
  end

  local stat = uv.fs_fstat(source)
  if not stat then
    uv.fs_close(source)
    error(string.format("Failed to stat source file: %s", src))
    return
  end

  local data = uv.fs_read(source, stat.size, 0)
  uv.fs_close(source)

  local dest = uv.fs_open(dst, "w", 438)
  if not dest then
    error(string.format("Failed to open destination file: %s", dst))
    return
  end

  uv.fs_write(dest, data)
  uv.fs_close(dest)
end

---Create backup of database file
---@param db_path string Path to database file
---@param backup_dir string Path to backup directory
---@return string|nil # Backup file path or nil if backup failed
local function create_backup(db_path, backup_dir)
  -- Check if source file exists
  if fn.filereadable(db_path) == 0 then
    return
  end

  local timestamp = os.date("%Y%m%d_%H%M%S")
  local backup_path = string.format("%s/bookmarks_%s.sqlite.db", backup_dir, timestamp)
  copy_file(db_path, backup_path)
  return backup_path
end

---Setup backup with 5-minute delay
---@param config table
---@param db_path string
function M.setup(config, db_path)
  if not config.backup.enabled then
    return
  end

  local backup_dir = get_backup_dir(config.backup.dir)
  ensure_backup_dir(backup_dir)

  -- Create a one-shot timer for delayed backup
  local timer = uv.new_timer()
  timer:start(
    config.backup.delay * 60 * 1000,
    -- 5, -- For testing
    0,
    vim.schedule_wrap(function()
      create_backup(db_path, backup_dir)
      timer:close()
    end)
  )

  -- Store timer reference to prevent garbage collection
  M._timer = timer
end

return M
