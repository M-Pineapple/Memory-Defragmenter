# Changelog

All notable changes to Memory Defragmenter will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Fix for PDF export functionality in ExportManager
- Improved error handling for NSPrintOperation
- Enhanced documentation with badges and icons
- Contributing guidelines
- Changelog file

## [1.0.0] - 2025-06-11

### Added
- Initial release of Memory Defragmenter
- Core analysis engine for finding duplicate memories
- Semantic similarity detection using embeddings
- Smart consolidation algorithm
- Automatic backup system with SHA-256 verification
- Export functionality (JSON, CSV, Markdown, HTML, PDF)
- Native SwiftUI interface for macOS
- Real-time statistics and progress tracking
- Granular control over optimization process
- Archive table for deleted memories
- One-click restore from backups

### Technical Features
- Built with Swift 6.0 and Xcode 26 beta
- Uses SQLite3 for direct database access
- Accelerate framework for performance
- Atomic transactions for data safety
- SwiftUI Charts for visualizations

### Known Issues
- Swift 6 concurrency warnings (non-breaking)
- Large databases (>10,000 memories) may take several minutes to analyze

## [0.9.0-beta] - 2025-06-10

### Added
- Beta testing release
- Core functionality implementation
- Basic UI structure
- Test database generator

### Changed
- Refined clustering algorithm
- Improved memory merge logic

### Fixed
- SQLite binding issues
- Memory leak in analysis engine

---

## Roadmap for Future Versions

### [1.1.0] - Planned
- Performance optimizations for large databases
- Batch processing improvements
- Enhanced progress indicators

### [2.0.0] - Planned
- Scheduled automatic optimization
- Memory usage graphs over time
- Enhanced backup management UI
- Dark/Light mode theme switcher
- Cloud backup support
- Multi-database batch processing

[Unreleased]: https://github.com/yourusername/memory-defragmenter/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/memory-defragmenter/releases/tag/v1.0.0
[0.9.0-beta]: https://github.com/yourusername/memory-defragmenter/releases/tag/v0.9.0-beta
