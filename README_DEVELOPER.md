# Memory Defragmenter

## ⚠️ IMPORTANT: Developer Tool - Build Required

This is a **developer tool** that requires building from source. By building and running this tool, you acknowledge that:

- You understand the risks of modifying database files
- You will maintain your own backups
- You take full responsibility for any data modifications
- This tool is provided AS-IS with no warranties

## Installation Options

### Option 1: Build from Source (Recommended)

**Prerequisites:**
- Xcode 15 or later
- macOS 11.0 or later  
- Python 3.8+ with ChromaDB (`pip3 install chromadb`)
- Apple Developer account (free tier is fine)

**Steps:**
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/memory-defragmenter.git
   cd memory-defragmenter
   ```

2. Open in Xcode:
   ```bash
   open "Memory Defragmenter.xcodeproj"
   ```

3. Select your development team in Signing & Capabilities

4. Build and run (⌘R)

### Option 2: Homebrew (Coming Soon)

We're working on a Homebrew formula for easier installation. Check back soon!

```bash
# Future installation method
brew tap yourusername/memory-defragmenter
brew install --cask memory-defragmenter
```

## Why Build from Source?

1. **You control the code**: Review it, modify it, understand it
2. **No sandbox restrictions**: Full Python integration works perfectly
3. **Educational value**: Learn how the optimization works
4. **Customization**: Modify thresholds, add features, fix bugs
5. **Security**: You know exactly what you're running

## Disclaimer

**USE AT YOUR OWN RISK**

This tool modifies Memory Service MCP databases. While it creates backups automatically:

- Always maintain external backups of critical data
- Test on a copy of your database first
- Review all changes before applying them
- The authors assume no responsibility for data loss

By building and using this tool, you accept full responsibility for any outcomes.

## Support

- **Issues**: Use GitHub Issues for bug reports
- **Discussions**: Share experiences and tips
- **PRs**: Improvements welcome!

Remember: This is a community tool by developers, for developers. Handle with care! 🛠️
