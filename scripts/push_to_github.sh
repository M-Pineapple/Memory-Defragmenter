#!/bin/bash

# Push to GitHub script for Memory Defragmenter

echo "Pushing Memory Defragmenter to GitHub..."
echo ""

# Check current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: $CURRENT_BRANCH"

# Push to origin
echo ""
echo "Pushing to origin/$CURRENT_BRANCH..."
git push origin $CURRENT_BRANCH

echo ""
echo "✅ Push complete!"
echo ""
echo "Next steps:"
echo "1. Go to https://github.com/m-pineapple/memory-defragmenter"
echo "2. Create a new release with version v1.0.0"
echo "3. Upload the DMG file from the releases"
echo "4. Make the repository public in Settings"
echo ""
echo "Remember to:"
echo "- Add topics like 'mcp', 'memory-service', 'macos', 'swift'"
echo "- Update the repository description"
echo "- Add a link to @doobidoo's Memory Service MCP"
