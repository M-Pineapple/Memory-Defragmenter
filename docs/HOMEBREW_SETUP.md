# Setting Up Homebrew Installation

To enable Homebrew installation for Memory Defragmenter, you'll need to create a separate Homebrew tap repository.

## Steps:

### 1. Create a new GitHub repository

Create a new repository named `homebrew-memory-defragmenter` on GitHub.

### 2. Add the Cask formula

Create a `Casks` directory and add the formula:

```bash
mkdir Casks
cp homebrew/memory-defragmenter-cask.rb Casks/memory-defragmenter.rb
```

### 3. Update the formula

Edit `Casks/memory-defragmenter.rb`:
- Replace `yourusername` with `m-pineapple`
- After creating the DMG, update `YOUR_SHA256_HERE` with the actual SHA256

To get the SHA256:
```bash
shasum -a 256 MemoryDefragmenter-1.0.0.dmg
```

### 4. Push to GitHub

```bash
git init
git add .
git commit -m "Add Memory Defragmenter cask"
git branch -M main
git remote add origin https://github.com/m-pineapple/homebrew-memory-defragmenter.git
git push -u origin main
```

### 5. Test installation

```bash
brew tap m-pineapple/memory-defragmenter
brew install --cask memory-defragmenter
```

## Formula Template

The formula is already prepared in `homebrew/memory-defragmenter-cask.rb` with:
- Automatic updates enabled
- macOS Sequoia requirement
- Proper app cleanup on uninstall
- GitHub release URL structure

## Notes

- The DMG must be uploaded to GitHub releases
- The SHA256 must match the uploaded DMG
- Users can then simply run the two brew commands to install
