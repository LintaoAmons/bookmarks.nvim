local common = require("bookmarks.adapter.common")

local function array_equal(t1, t2)
  if #t1 ~= #t2 then
    return false
  end

  for i = 1, #t1, 1 do
    if t1[i] ~= t2[i] then
      return false
    end
  end
  return true
end

local function test_parse_command()
  local result = common.parse_command("!newlist newbookmarklist")
  print("DEBUGPRINT[1]: common_test.lua:17: result=" .. vim.inspect(result))

  if result.is_command == true and result.command == "newlist" and array_equal(result.args, { "newbookmarklist" }) then
    return true
  else
    error("test_parse_command failed")
  end
end

return {
  test_parse_command = test_parse_command,
}
