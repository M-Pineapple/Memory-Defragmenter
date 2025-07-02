# Changelog

All notable changes to Memory Defragmenter will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-07-02

### Initial Release

Memory Defragmenter is a standalone macOS application that optimizes [Memory Service MCP](https://github.com/doobidoo/mcp-memory-service) databases.

#### Features
- 🔍 **Intelligent Analysis**: Finds duplicate and similar memories using semantic similarity
- 🎯 **Smart Consolidation**: Merges related memories while preserving unique information  
- 🛡️ **Safety First**: Automatic backups before any optimization
- 🔄 **One-Click Restore**: Easily revert to any backup
- 📊 **Visual Analytics**: Interactive charts showing cluster distributions and potential savings
- 📑 **Export Options**: Export analysis results as JSON, CSV, Markdown, HTML, or PDF

#### Technical
- Built with Swift 6.0 and SwiftUI
- Native macOS application (requires macOS 11.0+)
- Supports both Apple Silicon and Intel Macs
- ChromaDB integration for working with Memory Service MCP databases
