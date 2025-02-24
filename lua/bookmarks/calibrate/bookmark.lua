local M = {}

---Find the closest matching line number to current_line
---@param file file*
---@param content string
---@param current_line number
---@return number new_line_no # -1 if not found, otherwise the closest matching line number
local function fullmatchStrategy(file, content, current_line)
  local matches = {}
  local line_no = 0

  -- Collect all matching lines
  for line in file:lines() do
    line_no = line_no + 1
    if line == content then
      table.insert(matches, line_no)
    end
  end

  if #matches == 0 then
    return -1
  end

  if #matches == 1 then
    return matches[1]
  end

  -- Find the closest match to current_line
  local closest = matches[1]
  local min_diff = math.abs(current_line - closest)

  for i = 2, #matches do
    local diff = math.abs(current_line - matches[i])
    if diff < min_diff then
      min_diff = diff
      closest = matches[i]
    end
  end

  return closest
end

---@param self Bookmarks.Node
---@return {has_msg: boolean, msg: string, changed: boolean}
function M.calibrate(self)
  if not self.content or self.content == "" then
    return { has_msg = false, msg = "", changed = false }
  end

  local prefix = string.format("[%s]%s:%s ----> ", self.name, self.location.path, self.content)
  local file = io.open(self.location.path, "r")

  if not file then
    return { has_msg = true, msg = prefix .. "file not found", changed = false }
  end

  local new_line_no = fullmatchStrategy(file, self.content, self.location.line)
  file:close()

  if new_line_no == -1 then
    return { has_msg = true, msg = prefix .. "content not found", changed = false }
  end

  if new_line_no == self.location.line then
    return { has_msg = false, msg = "", changed = false }
  end

  local msg = string.format("line number changed from %d to %d", self.location.line, new_line_no)
  self.location.line = new_line_no

  return { has_msg = true, msg = prefix .. msg, changed = true }
end

return M
