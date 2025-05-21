## Updating CHANGELOG.md

When making changes to the codebase, follow these steps to update the `CHANGELOG.md` file:

1. **Version Entry**: If the change is part of a new version, create a new version entry at the top of the changelog (right after the initial headings). Use the format `## [X.Y.Z] - YYYY-MM-DD` where `X.Y.Z` is the new version number following Semantic Versioning, and `YYYY-MM-DD` is the release date.
2. **Categorize Changes**: Under the new version entry, categorize the changes into sections such as `Added`, `Changed`, `Fixed`, etc., as per the Keep a Changelog format.
3. **Describe Changes**: For each change, provide a concise bullet point description that clearly explains what was modified or added. Reference the specific feature or fix, and if applicable, link to the relevant GitHub issue or pull request.
4. **Preserve Existing Content**: Ensure that existing changelog entries are not modified or removed. Only add new content for the current changes.

Example:
```
## [0.13.0] - 2025-05-20

### Added
- New feature to support unique project IDs for accurate deletion

### Changed
- Updated project deletion logic to use unique IDs instead of names
```

## Updating RELEASE_NOTES.md

When preparing a new release, update the `RELEASE_NOTES.md` file with the following structure:

1. **Title**: Update the title to reflect the new version, e.g., `# vX.Y.Z Release Notes`.
2. **Major Changes**: Under `## Major Changes`, describe the significant updates or features introduced in this version. Provide a brief overview of each major change with a subheading if necessary.
3. **Upgrading Instructions**: Under `## Upgrading from vX.Y.Z`, inform users about any breaking changes or specific steps needed to upgrade from the previous version. If there are no breaking changes, state that explicitly.
4. **Reference to Changelog**: At the end, include a link to the `CHANGELOG.md` for a complete list of changes.

Example:
```
# v0.13.0 Release Notes

## Major Changes

### Unique Project IDs
- Introduced unique IDs for projects to ensure accurate deletion even when projects share the same name.

## Upgrading from v0.12.0
No breaking changes in this release. The unique ID feature is automatically applied to new and existing projects. No additional configuration is needed.

For a complete list of changes, see the [CHANGELOG.md](CHANGELOG.md).
```

## Version Upload Convention

When updating the version of `bookmarks.nvim`, follow Semantic Versioning (MAJOR.MINOR.PATCH):
- **MAJOR version** (first number) is incremented for breaking changes that are not backward compatible.
- **MINOR version** (second number) is incremented for new features that are backward compatible.
- **PATCH version** (third number) is incremented for bug fixes or minor changes that are backward compatible.

Ensure that any breaking changes result in a major version increment (e.g., from 0.12.1 to 1.0.0).

