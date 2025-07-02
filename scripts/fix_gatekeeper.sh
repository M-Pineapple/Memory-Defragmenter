#!/bin/bash

# Fix Gatekeeper issues for unsigned apps during development/testing

echo "Fixing Gatekeeper restrictions for Memory Defragmenter..."

# Remove quarantine attributes
APP_PATH="/Applications/Memory Defragmenter.app"

if [ -d "$APP_PATH" ]; then
    echo "Removing quarantine attributes from: $APP_PATH"
    sudo xattr -cr "$APP_PATH"
    
    echo ""
    echo "✅ Done! You should now be able to open the app."
    echo ""
    echo "Alternative methods if this doesn't work:"
    echo "1. Right-click the app and select 'Open' (do this twice if needed)"
    echo "2. Go to System Settings > Privacy & Security and click 'Open Anyway'"
    echo "3. Or run: sudo spctl --master-disable (disables Gatekeeper completely - not recommended)"
else
    echo "❌ Error: App not found at $APP_PATH"
    echo "Please ensure Memory Defragmenter is installed in /Applications"
fi

echo ""
echo "For production releases, you'll need to:"
echo "- Sign the app with an Apple Developer certificate"
echo "- Notarize it with Apple"
echo "- This ensures users don't see this warning"
