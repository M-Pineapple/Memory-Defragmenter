# GitHub Actions Disabled

Since Memory Defragmenter is distributed as source-only (to avoid liability), 
the automated build workflows have been disabled.

Users must build from source using Xcode. See BUILD_GUIDE.md for instructions.

## Disabled Workflows:
- release.yml - Was used for automated DMG/tarball creation
- tests.yml - Was used for automated testing

These used deprecated actions (v3) which are no longer supported by GitHub.
