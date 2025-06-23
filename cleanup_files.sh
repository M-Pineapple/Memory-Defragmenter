#!/bin/bash
# Cleanup old files
rm -f INSTALLATION.md.old
rm -f PUBLIC_RELEASE_PREP.md.old
rm -f homebrew/memory-defragmenter.rb.old
rm -f scripts/debug_python.py.bak
rm -f cleanup.sh
rmdir homebrew 2>/dev/null || true
echo "Cleanup completed!"
