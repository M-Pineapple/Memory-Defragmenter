# Memory Defragmenter v1.0.0

## 🎉 Initial Public Release

Memory Defragmenter is now available as an open-source companion tool for [Memory Service MCP](https://github.com/doobidoo/mcp-memory-service) by [@doobidoo](https://github.com/doobidoo).

### What is Memory Defragmenter?

A standalone macOS application that optimizes Memory Service MCP databases by:
- Finding and merging duplicate memories
- Consolidating similar content
- Providing visual analytics of your memory database
- Creating automatic backups before any changes

### Key Features

- 🔍 **Smart Analysis** - Uses semantic similarity to find related memories
- 🛡️ **Safety First** - Automatic backups before optimization
- 📊 **Visual Analytics** - See your memory usage patterns
- 📑 **Export Options** - Save results as JSON, CSV, Markdown, HTML, or PDF
- 🎨 **Native macOS** - Built with SwiftUI for the best Mac experience

### Requirements

- macOS 11.0 (Big Sur) or later
- Xcode 15+ to build from source
- Python 3.8+ with ChromaDB for full functionality

### Installation

This is a developer tool that must be built from source:

```bash
git clone https://github.com/M-Pineapple/Memory-Defragmenter.git
cd Memory-Defragmenter
open "Memory Defragmenter.xcodeproj"
# Build with ⌘R in Xcode
```

See [BUILD_GUIDE.md](BUILD_GUIDE.md) for detailed instructions.

### Special Thanks

Huge thanks to [@doobidoo](https://github.com/doobidoo) for creating the excellent Memory Service MCP that this tool is built for! 

---

Made with ❤️ 🍍
