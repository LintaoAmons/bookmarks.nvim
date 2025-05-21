# v2.10.0 Release Notes

## Major Changes

### Bookmark Linking Functionality
- Added the ability to link bookmarks to each other, creating associations for better organization and navigation.
- New commands `BookmarksLink` to link bookmarks and `BookmarksViewLinked` to view linked bookmarks.
- Additional commands for managing linked bookmarks:
  - `Link bookmark` to link a bookmark to another.
  - `Goto linked out bookmarks` to navigate to bookmarks linked from the current one.
  - `Goto linked in bookmarks` to navigate to bookmarks that link to the current one.
  - `Mark and link to existing bookmark` to mark a new bookmark and immediately link it to an existing one.
- Visual indicator (🔗 icon) in the tree view for bookmarks that have links.

### Enhanced Command Set
- Introduced new commands for better bookmark management:
  - `BookmarksDesc` for adding descriptions to bookmarks.
  - `BookmarksGrep` for searching through content of bookmarked files.
  - `BookmarksInfo` for an overview of plugin status.
  - `BookmarksInfoCurrentBookmark` to display information about the current bookmark.

### Info Package Improvements
- Enhanced the `info` package to provide detailed insights into bookmark status, structure, and relationships, improving user understanding and interaction with bookmarks.

## Upgrading from v2.9.0
No breaking changes in this release. The new commands and info enhancements are automatically available upon updating. Ensure your configuration includes the latest keybindings or command mappings if you wish to use the new functionalities.

For a complete list of changes, see the [CHANGELOG.md](CHANGELOG.md).
                                                                                          
## Upgrading from v0.0.0                                                                  
This is the initial release, so there are no upgrading instructions from previous         
versions. For installation and setup, refer to the README.md.                             
                                                                                          
For a complete list of changes, see the [CHANGELOG.md](CHANGELOG.md).                     
