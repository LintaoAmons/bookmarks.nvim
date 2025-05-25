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
