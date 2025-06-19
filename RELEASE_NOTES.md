# v3.2.0 Release Notes

## Key Enhancements

### Neo-tree Integration
- **Bookmark from File Explorer**: Seamlessly mark files or entire directories for bookmarking directly from the Neo-tree file explorer. This integration streamlines the process of adding bookmarks while navigating your project.
- **Customizable Keymap**: A new section in `ADVANCED_USAGE.md` provides an example of how to add a custom keymap to your Neo-tree configuration to trigger the bookmarking action. This allows for flexible integration into your existing workflow.
- **Recursive Directory Marking**: When a directory is selected in Neo-tree, the example integration will recursively find and mark all files within that directory.

```lua
-- Example Neo-tree mapping (see ADVANCED_USAGE.md for full context):
-- In your neo-tree opts.window.mappings:
-- ["<leader>bm"] = {
--   function(state)
--     local node = state.tree:get_node()
--     -- ... logic to get files from node ...
--     local files_to_mark = get_all_files_from_node(node) -- (helper function)
--     local bookmarks_api = require("bookmarks.api")
--     for _, file_path in ipairs(files_to_mark) do
--       bookmarks_api.markfile(file_path)
--     end
--     vim.notify("Bookmarked file(s) from Neo-tree.", vim.log.levels.INFO)
--   end,
--   desc = "Bookmark file/directory from Neo-tree",
-- }
```

## Upgrading
This release adds new integration capabilities and should not introduce breaking changes to existing configurations unless you have custom integrations that might conflict with the new `markfile` usage from Neo-tree.

---

# v3.1.0 Release Notes

## Key Enhancements

### Improved Tree View Preview
- **Smarter Preview Windows**: The tree view preview (shortcut `P` or `preview` action) is now more intelligent.
    - If you preview a bookmark that's already open in a preview window, Neovim will simply focus that existing window.
    - When you preview a new bookmark, any previously open preview window for a different bookmark will be automatically closed. This keeps your workspace tidy.
- **Cursor Stability**: When previewing a bookmark from the tree view, the cursor will remain in the tree view. This provides a smoother experience, especially when quickly browsing through multiple bookmarks.

### New API for Programmatic Bookmarking
- Introduced `mark_the_location_into_a_spetial_list(list_name)` API. This allows other plugins or custom configurations to programmatically add bookmarks to a designated list.
For example, you can now easily create a "LSP Jumps" list that automatically records locations from `gd` (go to definition) actions.

```lua
-- Example usage in your Neovim config:
vim.keymap.set("n", "gd", function()
  -- Ensure the API function is available
  pcall(require("bookmarks.api").mark_the_location_into_a_spetial_list, "LSP Jumps")
  vim.lsp.buf.definition()
end, { desc = "Go to Definition and mark location" })
```

## Upgrading
This release builds upon v3.0.0 and should not introduce breaking changes to existing configurations unless directly interacting with the modified preview or goto_bookmark internals.

---

# v3.0.0 Release Notes

## Major Changes

### Enhanced Tree View Keymap Configuration
- Introduced a new keymap structure for the tree view that supports custom actions with descriptive metadata.
- Updated the format to be more flexible, allowing users to define custom behaviors with ease.
- Changed the Aider integration dependency to `GeorgesAlkhouri/nvim-aider`.

#### Custom Action Demo
You can define custom actions in the `treeview.keymap` configuration. Here's an example of a custom action that opens the directory of a bookmark with the system default file explorer:

```lua
["<C-o>"] = {
  ---@type Bookmarks.KeymapCustomAction
  action = function(node, info)
    if info.type == 'bookmark' then
      vim.system({'open', info.dirname}, { text = true })
    end
  end,
  desc = "Open the current node with system default software",
}
```

**Signature of a Custom Action:**
```lua
---@param node Bookmarks.Node The node object representing the bookmark or list.
---@param info Bookmarks.ActionNodeInfo Information about the node, including type, path, and dirname.
function(node, info)
  -- Custom logic here
end
```

### Breaking Changes
- **Tree View Keymap Format**: The keymap configuration in `treeview.keymap` has changed. Users with custom keymaps must update their configurations to match the new format as shown in `default-config.lua`.

## Upgrading from v2.11.0
This release includes breaking changes. If you have customized the tree view keymaps in your configuration, you will need to update them to the new format. Refer to the updated `default-config.lua` for the new structure. Additionally, note that bookmark linking commands have been removed; if you rely on these, consider maintaining a custom fork or reaching out for alternative solutions.

For a complete list of changes, see the [CHANGELOG.md](CHANGELOG.md).
