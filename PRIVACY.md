# Memory Defragmenter - Privacy Policy

## Your Privacy Matters

Memory Defragmenter is designed with privacy as a core principle. This document explains how the app handles your data.

## Data Processing

### Local Processing Only
- **All processing happens locally** on your Mac
- **No internet connection required** for core functionality
- **No telemetry or analytics** are collected
- **No data is sent to external servers**

### What Data the App Accesses
- **Memory Service MCP databases**: Read and write access to optimize your memories
- **File system**: Access to open databases and save optimized results
- **Python runtime**: Executes local Python scripts for ChromaDB operations

### Data Storage
- **Original databases**: Never modified directly
- **Backups**: Created automatically before optimization in the same directory
- **Temporary files**: Stored in system temp directory and cleaned up after use
- **App preferences**: Stored in `~/Library/Preferences/Current-Labs.Memory-Defragmenter.plist`

## Security Measures

### Code Signing
- The app is signed with a Developer ID certificate
- Notarized by Apple for additional security verification
- Uses Hardened Runtime for enhanced security

### Permissions
- **No network access**: The app has no ability to connect to the internet
- **No camera/microphone access**: Not requested or used
- **File access only**: Limited to user-selected database locations

## Your Memory Data

### What We Don't Do
- We don't read your memory content for any purpose other than optimization
- We don't store copies of your memories beyond the backup process
- We don't analyze your personal data
- We don't share any data with third parties

### What the App Does
- Analyzes memory similarity using local vector comparisons
- Groups similar memories for consolidation
- Creates local backups before making changes
- Optimizes database structure for better performance

## Open Source Transparency

Memory Defragmenter is open source, which means:
- You can inspect the entire source code
- You can verify these privacy claims yourself
- You can build the app from source if desired
- Community oversight helps ensure privacy

## Backup Safety

Before any optimization:
1. A complete backup is created automatically
2. Backups are timestamped for easy identification
3. Original data is preserved in case of issues
4. You control when to delete old backups

## Third-Party Components

The app uses:
- **ChromaDB**: Open-source vector database (runs locally)
- **Python**: For ChromaDB operations (runs locally)
- **SwiftUI**: Apple's framework for the user interface

None of these components send data externally when used by Memory Defragmenter.

## Data Deletion

To remove all app data:
1. Delete the app from Applications
2. Remove preferences: `~/Library/Preferences/Current-Labs.Memory-Defragmenter.plist`
3. Delete any backups you've created
4. The app leaves no other traces on your system

## Updates

- App updates are distributed through GitHub releases
- No automatic update mechanism that could compromise privacy
- You control when and if to update

## Contact

If you have privacy-related questions:
- Open an issue on [GitHub](https://github.com/yourusername/memory-defragmenter/issues)
- Review the source code for verification
- Contribute privacy improvements via pull requests

## Changes to This Policy

Any changes to this privacy policy will be:
- Announced in release notes
- Updated in this document
- Communicated through GitHub releases

Last updated: June 2025

---

**Remember**: Your memories are yours alone. Memory Defragmenter is simply a tool to help you organize them better, with complete respect for your privacy.
