local M = {}

-- Function to merge bookmarked files into one file in XML format
function M.mix_active_list(output_path)
  local active_list = require("bookmarks.domain.repo").ensure_and_get_active_list()
  local bookmarks = require("bookmarks.domain.node").get_all_bookmarks(active_list)
  local output_file = io.open(output_path, "w")

  if not output_file then
    error("Failed to open output file: " .. output_path)
  end

  output_file:write('<?xml version="1.0" encoding="UTF-8"?>\n')
  output_file:write("<mixed_representation>\n")
  output_file:write("  <file_summary>\n")
  output_file:write("    <purpose>\n")
  output_file:write("      This file contains a packed representation of the bookmarked files.\n")
  output_file:write("      It is designed to be easily consumable by AI systems for analysis, code review,\n")
  output_file:write("      or other automated processes.\n")
  output_file:write("    </purpose>\n")
  output_file:write("    <file_format>\n")
  output_file:write("      The content is organized as follows:\n")
  output_file:write("      1. This summary section\n")
  output_file:write("      2. Repository information\n")
  output_file:write("      3. Directory structure\n")
  output_file:write("      4. Repository files, each consisting of:\n")
  output_file:write("        - File path as an attribute\n")
  output_file:write("        - Full contents of the file\n")
  output_file:write("    </file_format>\n")
  output_file:write("    <usage_guidelines>\n")
  output_file:write("      - This file should be treated as read-only. Any changes should be made to the\n")
  output_file:write("        original repository files, not this packed version.\n")
  output_file:write("      - When processing this file, use the file path to distinguish\n")
  output_file:write("        between different files in the repository.\n")
  output_file:write("      - Be aware that this file may contain sensitive information. Handle it with\n")
  output_file:write("        the same level of security as you would the original repository.\n")
  output_file:write("    </usage_guidelines>\n")
  output_file:write("    <notes>\n")
  output_file:write("      - Some files may not belong to the git project repo, they are using as references\n")
  output_file:write("    </notes>\n")
  output_file:write("  </file_summary>\n")
  output_file:write("  <directory_structure>\n")
  for _, bookmark in ipairs(bookmarks) do
    if bookmark.location then
      output_file:write("    <file>" .. bookmark.location.path .. "</file>\n")
    end
  end
  output_file:write("  </directory_structure>\n")
  output_file:write("  <bookmark_list_name>" .. active_list.name .. "</bookmark_list_name>\n")
  output_file:write("  <files>\n")

  for _, bookmark in ipairs(bookmarks) do
    if bookmark.location then
      local file_path = bookmark.location.path
      local file = io.open(file_path, "r")

      if file then
        output_file:write('    <file path="' .. file_path .. '">\n')
        output_file:write("      <mark_name>" .. bookmark.name .. "</mark_name>\n")
        output_file:write("      <marked_line>" .. bookmark.content .. "</marked_line>\n")
        output_file:write("      <content>\n")

        for line in file:lines() do
          output_file:write("        " .. line .. "\n")
        end

        output_file:write("      </content>\n")
        output_file:write("    </file>\n")
        file:close()
      else
        output_file:write('    <file path="' .. file_path .. '">\n')
        output_file:write("      <error>Failed to open file</error>\n")
        output_file:write("    </file>\n")
      end
    end
  end

  output_file:write("  </files>\n")
  output_file:write("</mixed_representation>\n")
  output_file:close()
end

return M
