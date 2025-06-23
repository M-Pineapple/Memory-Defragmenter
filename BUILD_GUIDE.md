# Building Memory Defragmenter

## Prerequisites

1. **macOS 11.0** (Big Sur) or later
2. **Xcode 15** or later (free from Mac App Store)
3. **Apple ID** (free developer account is sufficient)
4. **Python 3.8+** with ChromaDB:
   ```bash
   pip3 install chromadb
   ```

## Build Steps

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/memory-defragmenter.git
cd memory-defragmenter
```

### 2. Open in Xcode
```bash
open "Memory Defragmenter.xcodeproj"
```

### 3. Configure Signing
1. Select the project in the navigator
2. Go to "Signing & Capabilities" tab
3. Check "Automatically manage signing"
4. Select your Team (your Apple ID)

### 4. Build and Run
- Press **⌘R** or click the ▶️ button
- The app will build and launch

## First Run

1. Click "Open Database"
2. Navigate to your Memory Service MCP database folder
3. Select the `chroma_db` directory
4. Start optimizing!

## Troubleshooting

### "Signing for 'Memory Defragmenter' requires a development team"
- Go to Xcode → Settings → Accounts
- Add your Apple ID
- Download certificates

### "Python not found" error
- Ensure ChromaDB is installed: `pip3 install chromadb`
- Check Python path: `which python3`

### Build errors
- Clean build folder: **⌘⇧K**
- Delete derived data: **⌘⇧⌥K**
- Restart Xcode

## Important Notes

- The app runs **without sandbox restrictions** when built from source
- This allows full Python integration to work properly
- Always backup your database before optimizing
- Test on a copy first!

## Need Help?

- Check [GitHub Issues](https://github.com/yourusername/memory-defragmenter/issues)
- Join the discussion in [GitHub Discussions](https://github.com/yourusername/memory-defragmenter/discussions)
