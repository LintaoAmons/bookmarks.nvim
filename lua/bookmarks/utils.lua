local function trim(str)
    return str:gsub("^%s+", ""):gsub("%s+$", "")
end

return {
  trim = trim
}

