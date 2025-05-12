# Bookmark Linking Functionality

## Overview

The `link_bookmarks` feature in `bookmarks.nvim` allows users to create associations between bookmarks. This is useful for connecting related pieces of code, documentation, or any other content marked by bookmarks, making navigation and organization more intuitive.

## Usage

### Linking Bookmarks

To link one bookmark to another, you can use the `link_bookmark` function. This functionality is accessible via the command or keybinding set in your configuration. Here's how it works:

1. **Select a Bookmark**: Place your cursor on a line with an existing bookmark or select a bookmark from the list.
2. **Initiate Linking**: Run the command or keybinding for linking (e.g., `:BookmarksLink` or a mapped key).
3. **Choose Target Bookmark**: A picker interface will appear, allowing you to select another bookmark to link to the current one.
4. **Confirmation**: Once selected, the bookmarks will be linked, and a confirmation message will be displayed.

### Viewing Linked Bookmarks

To view bookmarks linked to the current one:

1. **Select a Bookmark**: Place your cursor on a line with a bookmark.
2. **View Linked Bookmarks**: Use the command or keybinding for viewing linked bookmarks (e.g., `:BookmarksViewLinked` or a mapped key).
3. **Navigate**: A picker will show all bookmarks linked to the current one, allowing you to navigate to any of them.

### Unlinking Bookmarks

Currently, unlinking is supported programmatically via the API but may not be exposed in the default UI. You can use the `unlink_bookmarks` function in a custom command or script if needed.

## API

### `link_bookmarks(bookmark_id, target_bookmark_id)`

- **Parameters**:
  - `bookmark_id`: The ID of the source bookmark.
  - `target_bookmark_id`: The ID of the bookmark to link to.
- **Returns**: `boolean` - `true` if linking was successful, `false` otherwise.
- **Description**: Creates a link between two bookmarks, storing the relationship in the database.

### `unlink_bookmarks(bookmark_id, target_bookmark_id)`

- **Parameters**:
  - `bookmark_id`: The ID of the source bookmark.
  - `target_bookmark_id`: The ID of the linked bookmark to remove.
- **Returns**: `boolean` - `true` if unlinking was successful, `false` otherwise.
- **Description**: Removes the link between two bookmarks from the database.

### `get_linked_bookmarks(bookmark_id)`

- **Parameters**:
  - `bookmark_id`: The ID of the bookmark to query.
- **Returns**: `Bookmarks.Node[]` - An array of bookmark nodes linked to the specified bookmark.
- **Description**: Retrieves all bookmarks linked to the given bookmark.

## Visual Indicators

In the tree view, bookmarks with links are marked with a `🔗` icon next to their name, making it easy to identify bookmarks that are connected to others.

## Database Structure

The linking information is stored in a separate table `bookmark_links` in the SQLite database, with the following schema:
- `id`: Unique identifier for the link.
- `bookmark_id`: The ID of the source bookmark.
- `linked_bookmark_id`: The ID of the target bookmark.
- `created_at`: Timestamp when the link was created.

This structure allows for efficient querying and management of bookmark relationships.

## Customization

You can customize how linked bookmarks are displayed or accessed by modifying the configuration or adding custom commands in your `bookmarks.nvim` setup. For example, you might add keybindings for quick linking or viewing linked bookmarks.

## Limitations

- Currently, linking is unidirectional. If you need bidirectional linking, you must explicitly link both bookmarks to each other.
- The UI for unlinking bookmarks might not be available by default and may require custom scripting or future plugin updates.

## Example

```lua
-- Link two bookmarks
require("bookmarks.domain.service").link_bookmarks(1, 2)

-- View linked bookmarks for a specific bookmark
local linked = require("bookmarks.domain.service").get_linked_bookmarks(1)
for _, bm in ipairs(linked) do
  print(bm.name)
end
```

This documentation provides a comprehensive guide to using the bookmark linking feature in `bookmarks.nvim`. For further customization or advanced usage, refer to the plugin's API documentation or configuration options.
