# Quick Installation Guide

## For Users

### Easiest Method: Homebrew (2 commands)

```bash
brew tap m-pineapple/memory-defragmenter
brew install --cask memory-defragmenter
```

Done! The app is now in your Applications folder.

### Alternative: Download DMG

1. Go to Releases page
2. Download the `.dmg` file
3. Drag app to Applications
4. Right-click → Open on first launch

## For Developers

### Setting up Homebrew distribution:

1. **Build the DMG**:
   ```bash
   ./scripts/build_dmg.sh 1.0.0
   ```

2. **Get SHA256**:
   ```bash
   shasum -a 256 MemoryDefragmenter-1.0.0.dmg
   ```

3. **Create tap repository**:
   - New repo: `homebrew-memory-defragmenter`
   - Add `Casks/memory-defragmenter.rb`
   - Update SHA256 and username
   - Push to GitHub

4. **Upload DMG** to GitHub Releases

That's all! Users can now install with brew.

## Python Dependencies

The app will prompt to install these on first run:
- numpy
- sentence-transformers

Or install manually:
```bash
pip3 install numpy sentence-transformers
```
