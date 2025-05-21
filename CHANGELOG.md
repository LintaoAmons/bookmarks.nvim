# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
