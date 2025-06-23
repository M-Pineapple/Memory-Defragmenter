# Memory Defragmenter for MCP

<div align="center">
  <img src="AppIcon_Unified.svg" width="128" height="128" alt="Memory Defragmenter Icon">
  
  **A standalone macOS application that optimizes Memory Service MCP databases**
  
  [![macOS](https://img.shields.io/badge/macOS-15.0+-blue.svg)](https://www.apple.com/macos/)
  [![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
  [![Xcode](https://img.shields.io/badge/Xcode-26_beta-blue.svg)](https://developer.apple.com/xcode/)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
</div>

## ⚠️ Developer Tool - Build From Source Required

This is an **open-source developer tool** that requires building from source code. By using this tool, you accept full responsibility for any data modifications. See [DISCLAIMER.md](DISCLAIMER.md) for important safety information.

## Overview

Memory Defragmenter is a companion tool for the excellent [Memory Service MCP](https://github.com/doobidoo/mcp-memory-service) by [@doobidoo](https://github.com/doobidoo). It intelligently consolidates redundant information, merges similar memories, and reorganizes content for improved retrieval performance in Memory Service MCP databases.

**⚠️ Important**: This tool directly modifies your database. Always maintain your own backups before using any optimization tool. While Memory Defragmenter creates automatic backups, you should never rely solely on built-in safety features. See [DISCLAIMER.md](DISCLAIMER.md) for full details.

## Features

### Core Functionality
- 🔍 **Intelligent Analysis**: Finds duplicate and similar memories using semantic similarity
- 🎯 **Smart Consolidation**: Merges related memories while preserving unique information
- 🛡️ **Safety First**: Automatic backups before any optimization
- 🔄 **One-Click Restore**: Easily revert to any backup

### User Interface
- 📊 **Visual Analytics**: Interactive charts showing cluster distributions and potential savings
- ✅ **Granular Control**: Review and approve each optimization individually
- 📈 **Real-time Statistics**: Live updates during analysis and optimization
- 🎨 **Native macOS Design**: Built with SwiftUI for a seamless Mac experience

### Export Options
- 📄 **Multiple Formats**: Export analysis results as JSON, CSV, Markdown, or HTML
- 📑 **PDF Reports**: Generate comprehensive optimization reports
- 💾 **Backup Management**: Easy access to all historical backups

## What Does It Solve?

Over time, Memory Service MCP databases can accumulate:
- **Duplicate memories**: The same information stored multiple times
- **Near-duplicate content**: Similar memories with slight variations
- **Fragmented information**: Related content scattered across multiple entries
- **Redundant embeddings**: Unnecessary vector data taking up space

Memory Defragmenter addresses these issues by:
- 🔍 Finding and merging duplicate memories using semantic similarity
- 🎯 Consolidating related information while preserving unique content
- 📊 Providing visual analytics to understand your memory database
- 🛡️ Ensuring data safety with automatic backups and rollback options

## ChromaDB Support

Memory Service MCP uses ChromaDB for vector storage. Memory Defragmenter now includes tools to work with ChromaDB:
- **Export** ChromaDB to SQLite for optimization
- **Import** optimized data back to ChromaDB
- See [ChromaDB Guide](docs/CHROMADB_GUIDE.md) for detailed instructions

## System Requirements

- **macOS**: 11.0 (Big Sur) or later
- **Processor**: Apple Silicon (M1/M2/M3) or Intel
- **Python**: 3.8 or later (for ChromaDB support)
- **Memory**: 4GB RAM minimum
- **Storage**: 100MB for app + space for database backups

## Installation

### Build from Source (Required)

This is a developer tool that must be built from source. See [BUILD_GUIDE.md](BUILD_GUIDE.md) for detailed instructions.

**Quick Start:**
```bash
# Clone the repository
git clone https://github.com/yourusername/memory-defragmenter.git
cd memory-defragmenter

# Open in Xcode
open "Memory Defragmenter.xcodeproj"

# Build and run with ⌘R
```

**Prerequisites:**
- Xcode 15 or later
- macOS 11.0 or later
- Apple Developer account (free tier is sufficient)
- Python 3.8+ with ChromaDB (`pip3 install chromadb`)

### Why Build from Source?

1. **You control the code** - Review and modify as needed
2. **No sandbox restrictions** - Python integration works perfectly
3. **Educational value** - Understand how optimization works
4. **Community driven** - Contribute improvements back
5. **Zero liability** - You build it, you own it

## Usage

1. **Locate Your Database**: Find your Memory Service MCP SQLite database file
   - Typically located in your MCP configuration directory
   - Look for files named `memory.db` or similar

2. **Open Database**: Click "Open Database" and select your Memory Service SQLite file

3. **Analyze**: Click "Start Analysis" to find duplicate clusters
   - The app will calculate semantic similarity between all memories
   - This may take a few minutes for large databases

4. **Review**: Examine suggested consolidations and select clusters to optimize
   - Each cluster shows memories that are similar or duplicate
   - You can preview the consolidated result before applying

5. **Optimize**: Click "Optimize" to apply changes
   - Automatic backup is created before any modifications
   - You can rollback at any time from the backup menu

## How It Works

The Memory Defragmenter uses a sophisticated multi-step process:

1. **Embedding Analysis**: 
   - Calculates semantic similarity between memories
   - Uses the same embedding model as Memory MCP for compatibility
   - Performs efficient batch processing for large databases

2. **Intelligent Clustering**: 
   - Groups similar memories (configurable similarity threshold, default: 85%)
   - Identifies exact duplicates and near-duplicates
   - Preserves temporal relationships and metadata

3. **Smart Consolidation**: 
   - Creates merged content preserving unique information
   - Maintains all original tags and metadata
   - Generates audit trail for changes

4. **Safe Optimization**: 
   - Updates the primary memory with consolidated content
   - Archives duplicates in a separate table
   - Maintains referential integrity

## Safety Features

- 🔒 **Mandatory Backups**: Automatic backup creation before any changes
- ⚛️ **Atomic Transactions**: All-or-nothing operations ensure database integrity
- 🔐 **Checksum Verification**: SHA-256 verification for backup integrity
- 📚 **Archive Preservation**: Deleted memories retained in archive table
- ↩️ **One-Click Rollback**: Instant restoration from any backup
- 📊 **Dry Run Mode**: Preview changes without modifying the database

## Development

### Technology Stack
- **Swift 6.0**: Leveraging new concurrency features and strict checking
- **SwiftUI 6.0**: Modern declarative UI with enhanced performance
- **SQLite3**: Direct database access with prepared statements
- **Accelerate Framework**: Hardware-accelerated similarity calculations
- **Charts Framework**: Native SwiftUI charts for analytics
- **AppKit Integration**: PDF generation and system notifications

### Project Structure
```
Memory Defragmenter/
├── Models/           # Data models and structures
├── Views/            # SwiftUI views and UI components
├── ViewModels/       # Business logic and state management
├── Services/         # Core services (Analysis, Optimization, Export)
├── Database/         # SQLite interface and queries
└── Assets.xcassets/  # App icons and resources
```

## Testing

### Unit Tests
```bash
swift test
```

### UI Tests
```bash
xcodebuild test -scheme "Memory Defragmenter" -destination "platform=macOS"
```

### Test Database
Generate a test database with sample data:
```bash
./create_test_db.sh
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Swift API Design Guidelines
- Add unit tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting PR

## Screenshots

<details>
<summary>Click to view screenshots</summary>

### Main Interface
_The main analysis view showing memory clusters and statistics_

### Optimization Results
_Visual representation of optimization savings and improvements_

### Export Options
_Various export formats for analysis results_

</details>

## Roadmap

### Version 2.0 (Planned)
- [ ] Scheduled automatic optimization
- [ ] Memory usage graphs over time
- [ ] Enhanced backup management UI
- [ ] Dark/Light mode theme switcher
- [ ] Cloud backup support
- [ ] Multi-database batch processing

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits & Acknowledgments

### Built On

This tool is built specifically for and as a companion to:
- **[Memory Service MCP](https://github.com/doobidoo/mcp-memory-service)** by [@doobidoo](https://github.com/doobidoo)
  - The excellent Memory Service MCP that this tool optimizes
  - All the hard work of memory storage, retrieval, and embedding generation
  - The robust SQLite database structure that makes optimization possible

### Inspired By
- Classic disk defragmentation tools
- Database optimization utilities
- The MCP (Model Context Protocol) ecosystem

### Created By
- Nicholas Rogers - Memory Defragmenter development
- With gratitude to [@doobidoo](https://github.com/doobidoo) for creating the Memory Service MCP

## ⚠️ Important Notes

### Data Safety
This tool directly modifies your Memory MCP database. While extensive safety measures are in place:
- **Always** ensure you have external backups of critical data
- Test on a copy of your database first
- Review all proposed changes before applying

### Performance Considerations
- Large databases (>10,000 memories) may take several minutes to analyze
- Similarity calculations are CPU-intensive
- Recommended: Close other applications during optimization

### Compatibility
- Designed specifically for [Memory Service MCP](https://github.com/doobidoo/mcp-memory-service) SQLite databases
- Not compatible with other memory/note-taking systems
- Requires matching embedding model versions
- Tested with Memory Service MCP v0.5.0 and later

---

<div align="center">
  Made with ❤️ for the MCP community
  
  Special thanks to [@doobidoo](https://github.com/doobidoo) for the amazing Memory Service MCP
</div>
