local M = {}

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

  local new_line_no = -1
  local line_no = 0

  for line in file:lines() do
    line_no = line_no + 1

    if line == self.content then
      if new_line_no == -1 then
        new_line_no = line_no
        if new_line_no == self.location.line then
          file:close()
          return { has_msg = false, msg = "", changed = false }
        end
      else
        file:close()
        return { has_msg = true, msg = prefix .. "content is not unique", changed = false }
      end
    end
  end

  file:close()

  if new_line_no == -1 then
    return { has_msg = true, msg = prefix .. "content not found", changed = false }
  end

  local msg = string.format("line number changed from %d to %d", self.location.line, new_line_no)
  self.location.line = new_line_no

  return { has_msg = true, msg = prefix .. msg, changed = true }
end

return M
