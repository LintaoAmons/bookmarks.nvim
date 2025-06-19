# Changelog

All notable changes to this project will be documented in this file.

## [3.2.0] - 2025-06-20

### Added
- Neo-tree integration: Added the ability to mark files or all files within a directory directly from Neo-tree using a custom keymap. See `ADVANCED_USAGE.md` for an example configuration.

## [3.1.0] - 2025-06-04

### Added
- New API `mark_the_location_into_a_spetial_list` to programmatically mark locations into a specified list (e.g., for LSP jumps).
- Option `keep_cursor` for the `goto_bookmark` service. When enabled, the cursor returns to its original window after a bookmark action, improving usability for tree view previews.

### Changed
- Tree view preview will now focus an existing preview window if it's already displaying the same bookmark, instead of opening a new one.
- Tree view preview will close any previously open preview window when a different bookmark is previewed.

### Fixed
- Ensured `special_list_id` is correctly used when refreshing the tree after `mark_the_location_into_a_spetial_list` to focus the relevant list.

## [3.0.0] - 2025-05-25

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2025-05-25

### Added
- Enhanced tree view keymap configuration with support for custom actions.
- Updated keymap structure to use a more descriptive and flexible format with action descriptions.
- Changed dependency for Aider integration to use `GeorgesAlkhouri/nvim-aider`.

### Changed
- **Breaking Change**: Tree view keymap configuration format has changed. Users need to update their custom keymaps to the new format as shown in the default configuration.

### Fixed
- Improved error handling and notifications for keymap setup in tree view.

## [2.11.0] - 2025-05-22

### Added
- Aider integration to add or drop bookmarked files directly into/from Aider sessions.
- New tree view operations for Aider integration:
  - `add_to_aider` to add bookmarked files to Aider.
  - `add_to_aider_read_only` to add bookmarked files to Aider as read-only.
  - `drop_from_aider` to drop bookmarked files from Aider.
- Default key mappings for Aider operations in tree view: `+` for add, `=` for add read-only, and `-` for drop.

## [2.10.0] - 2025-05-21

### Added
- Bookmark linking functionality to create associations between bookmarks.
- Commands `BookmarksLink` and `BookmarksViewLinked` for linking and viewing linked bookmarks.
- New commands for managing linked bookmarks:
  - `Link bookmark` to link a bookmark to another.
  - `Goto linked out bookmarks` to navigate to bookmarks linked from the current one.
  - `Goto linked in bookmarks` to navigate to bookmarks that link to the current one.
  - `Mark and link to existing bookmark` to mark a new bookmark and immediately link it to an existing one.
- Visual indicator (🔗 icon) in tree view for bookmarks with links.
- Enhanced `info` package to provide detailed insights into bookmark status and structure.

### Changed
- Updated command structure to improve user interaction and accessibility.

### Fixed
- Minor bug fixes and performance improvements in command execution and info display.
