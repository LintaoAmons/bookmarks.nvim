local M = {}

--- Function to merge bookmarked files into one file in XML format
---@param opts {open: boolean, notify: boolean}|nil Options for the function
---@return nil
function M.mix_active_list(opts)
  local opts = opts or {
    open = true,
  }
  local utils = require("bookmarks.utils")
  local xml = require("bookmarks.mix.format.xml")
  local project_path = utils.find_project_path()

  if (not project_path) or project_path == "" then
    vim.notify("Project path not found", vim.log.levels.WARN)
    return
  end

  -- Create XML file
  local xml_filename = "bookmarks_" .. os.date("%Y%m%d") .. ".xml"
  local xml_file_path = vim.fs.normalize(vim.fn.join({ project_path, xml_filename }, "/"))
  xml.mix_active_list(xml_file_path)

  -- Open the XML file in a new buffer if 'open' is true in opts
  if opts.open == true then
    vim.cmd("edit " .. xml_file_path)
  end

  -- Notify user of XML file location if 'notify' is true in opts
  if opts.notify == true then
    vim.notify("XML file created at: " .. xml_file_path, vim.log.levels.INFO)
  end
end

return M
