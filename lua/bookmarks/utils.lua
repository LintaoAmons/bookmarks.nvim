local function trim(str)
    return str:gsub("^%s+", ""):gsub("%s+$", "")
end
-- Function to shorten a file path
function shorten_file_path(file_path)
    local parts = {}
    
    for part in string.gmatch(file_path, "[^/]+") do
        table.insert(parts, string.sub(part, 1, 1))
    end
    
    return table.concat(parts, "/")
end
return {
  trim = trim,
  shorten_file_path = shorten_file_path,
}

