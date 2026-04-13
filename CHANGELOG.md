# Changelog

All notable changes to this project are documented in this file.

The format loosely follows Keep a Changelog and uses semantic versioning for project releases.

## [0.1.0] - 2026-04-13

### Added

- Added a root `VERSION` file to define the current project release as `0.1.0`.
- Added a project-level `CHANGELOG.md` for future release tracking.
- Added multilingual README entry points for English, Traditional Chinese, Japanese, Russian, and French.

### Changed

- Renamed the public project brand from `Limitless Search` to `FileSearch`.
- Migrated the internal Go module from `pansou` to `filesearch`.
- Renamed internal directories from `backend/limitless_search` to `backend/filesearch`.
- Renamed internal directories from `web/limitless_search_web` to `web/filesearch_web`.
- Updated Docker build paths, binary names, startup scripts, and image metadata to match `FileSearch`.
- Unified MCP package name, service name, resource URI, and internal versioning under `FileSearch`.
- Updated repository links and deployment documentation to use `https://github.com/cosmaut/FileSearch`.

### Security

- Enforced server-side captcha validation for the AI suggestion API.
- Added backend validation to reject empty search keywords.
- Hardened default ranking sync token handling and improved unsafe default token protection.
