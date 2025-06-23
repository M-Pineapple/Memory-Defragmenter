#!/bin/bash

# Create test database for Memory Defragmenter
echo "Creating test database..."

# Remove old test database if it exists
rm -f test_memory.db

# Create new database with test data
sqlite3 test_memory.db < test_database.sql

echo "Test database created: test_memory.db"
echo "This database contains:"
echo "- 10 test memories"
echo "- 3 groups of similar memories (Python, Swift, Memory MCP)"
echo "- 2 unique memories"
echo ""
echo "You can now open this database in Memory Defragmenter to test the functionality."
