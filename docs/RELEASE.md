# Release Process for Memory Defragmenter

This document outlines the process for creating and distributing new releases of Memory Defragmenter.

## Prerequisites

- Apple Developer account (for signing and notarization)
- Homebrew installed
- GitHub repository with release permissions
- Xcode 26 beta

## Release Steps

### 1. Update Version Numbers

Update version in the following files:
- `Memory Defragmenter.xcodeproj` (Project settings)
- `Package.swift`
- `CHANGELOG.md`
- Homebrew formulas

### 2. Build Release Artifacts

#### Build the DMG
```bash
./build_dmg.sh 1.0.0
```

This creates a DMG file with the app and installation scripts.

#### Build Homebrew Package
```bash
./build_homebrew_release.sh 1.0.0
```

This creates a tarball for Homebrew distribution.

### 3. Sign and Notarize (macOS)

```bash
# Sign the app
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  "Memory Defragmenter.app"

# Create DMG and sign it
./build_dmg.sh 1.0.0

# Notarize the DMG
xcrun notarytool submit MemoryDefragmenter-1.0.0.dmg \
  --apple-id your@email.com \
  --password @keychain:AC_PASSWORD \
  --team-id TEAMID \
  --wait

# Staple the notarization
xcrun stapler staple MemoryDefragmenter-1.0.0.dmg
```

### 4. Create GitHub Release

1. Tag the release:
```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

2. Create release on GitHub:
   - Go to Releases → New Release
   - Select the tag
   - Add release notes from CHANGELOG.md
   - Upload artifacts:
     - MemoryDefragmenter-1.0.0.dmg
     - MemoryDefragmenter-1.0.0.tar.gz

### 5. Update Homebrew Formulas

#### For the Tap Repository

1. Update SHA256 in formulas:
```ruby
sha256 "NEW_SHA256_FROM_BUILD_SCRIPT"
```

2. Test the formula:
```bash
brew install --verbose --debug memory-defragmenter
```

3. Submit to your tap:
```bash
cd homebrew-memory-defragmenter
git add .
git commit -m "Update Memory Defragmenter to 1.0.0"
git push
```

#### For Homebrew Cask (Main Repository)

1. Fork homebrew-cask
2. Create new branch
3. Update the cask formula
4. Test locally:
```bash
brew install --cask ./memory-defragmenter.rb
```
5. Submit PR to homebrew-cask

### 6. Update Documentation

- Update README.md with any new features
- Update the website/documentation
- Post release announcement

## Homebrew Tap Structure

Create a separate repository for your Homebrew tap:
```
homebrew-memory-defragmenter/
├── Formula/
│   └── memory-defragmenter.rb
└── Casks/
    └── memory-defragmenter.rb
```

## Testing Checklist

Before releasing, ensure:
- [ ] All tests pass
- [ ] App builds without warnings on target macOS versions
- [ ] DMG installs correctly
- [ ] Homebrew formula installs correctly
- [ ] Python dependencies install correctly
- [ ] Basic functionality works (open, analyze, optimize)
- [ ] Export features work
- [ ] Backup/restore works

## Version Numbering

Follow semantic versioning:
- MAJOR.MINOR.PATCH (e.g., 1.0.0)
- MAJOR: Breaking changes
- MINOR: New features, backwards compatible
- PATCH: Bug fixes

## Emergency Rollback

If issues are discovered:
1. Mark release as pre-release on GitHub
2. Revert Homebrew formula to previous version
3. Notify users via GitHub issues
4. Fix issues and create patch release

## Automation (Future)

Consider using GitHub Actions for:
- Automated builds
- Testing
- Release creation
- Homebrew formula updates
