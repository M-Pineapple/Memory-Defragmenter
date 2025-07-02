#!/bin/bash

# Fix permissions for test database
echo "Fixing database permissions..."

# Make the database writable
chmod 644 test_memory.db

# Check if successful
if [ -w test_memory.db ]; then
    echo "✅ Database is now writable"
    ls -la test_memory.db
else
    echo "❌ Failed to make database writable"
fi
