# Local Homebrew Installation Test Guide

Follow these steps to test the Homebrew installation locally:

## Step 0: Initialize Homebrew Tap Repository

Homebrew requires taps to be git repositories:

```bash
cd ../homebrew-memory-defragmenter  # Assuming it's in a sibling directory
git init
git add .
git commit -m "Initial commit - Memory Defragmenter Homebrew tap"
```

## Step 1: Create the Package

Run this in Terminal:

```bash
cd "Memory Defragmenter"  # From the project root

# Make the script executable
chmod +x scripts/create_test_package.sh

# Create the test package
./scripts/create_test_package.sh
```

This will create a zip file in the `dist/` directory.

## Step 2: Add the Local Tap

```bash
# Remove any existing tap first (if you've tried before)
brew untap rogers/memory-defragmenter 2>/dev/null || true

# Add your local tap (replace YOUR_USERNAME with your GitHub username)
# Replace /path/to/ with the actual path to your homebrew tap directory
brew tap YOUR_USERNAME/memory-defragmenter file:///path/to/homebrew-memory-defragmenter
```

## Step 3: Install the App

```bash
# Install via the tap
brew install --cask YOUR_USERNAME/memory-defragmenter/memory-defragmenter
```

Or install directly without tap:

```bash
brew install --cask /path/to/homebrew-memory-defragmenter/Casks/memory-defragmenter.rb
```

## Step 4: Verify Installation

The app should now be in your Applications folder. You can:

1. Check if it's installed:
   ```bash
   brew list --cask | grep memory-defragmenter
   ```

2. Launch it from Applications folder or:
   ```bash
   open "/Applications/Memory Defragmenter.app"
   ```

## Step 5: Uninstall (when done testing)

```bash
brew uninstall --cask memory-defragmenter
```

## Troubleshooting

### Gatekeeper Warning ("App Not Opened")

If you see a warning that Apple couldn't verify the app:

**Quick Fix:**
```bash
sudo xattr -cr "/Applications/Memory Defragmenter.app"
```

Or run the provided script:
```bash
chmod +x scripts/fix_gatekeeper.sh
./scripts/fix_gatekeeper.sh
```

**Alternative Methods:**
1. Right-click the app in Finder and select "Open" (you may need to do this twice)
2. Go to System Settings > Privacy & Security and click "Open Anyway"
3. Control-click the app and select "Open" from the menu

**Note:** This warning appears because the app isn't signed with an Apple Developer certificate. For production releases, you'll need to sign and notarize the app.

### Other Issues

If you encounter issues:

1. Check Homebrew's output for errors
2. Ensure the zip file exists:
   ```bash
   ls -la "./dist/"  # From the project root
   ```

3. Try installing with verbose output:
   ```bash
   brew install --cask --verbose /path/to/homebrew-memory-defragmenter/Casks/memory-defragmenter.rb
   ```

4. If the app doesn't have the correct permissions:
   ```bash
   xattr -cr "/Applications/Memory Defragmenter.app"
   ```
