# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-07-23

### Added
- Initial release: overlay fuzzy file finder for herdr (macOS).
- `fd` + `fzf` finder popup rooted at the focused pane's cwd, with `bat`
  syntax-highlighted preview.
- Customizable `open` action via a command template with `{uri}` / `{path}` /
  `{dir}` placeholders; default opens the file in a new Warp tab.

[Unreleased]: https://github.com/Duzc01/herdr-file-finder/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Duzc01/herdr-file-finder/releases/tag/v0.1.0
