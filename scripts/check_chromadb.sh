#!/bin/bash

DB_PATH="/Users/rogers/Desktop/chroma_db"

echo "=== Checking ChromaDB structure ==="
echo "Contents of $DB_PATH:"
ls -la "$DB_PATH"

echo -e "\n=== Checking for lock files ==="
find "$DB_PATH" -name "*.lock" -o -name "*-journal" -o -name "*-wal"

echo -e "\n=== Checking permissions ==="
echo "Directory permissions:"
ls -ld "$DB_PATH"
echo -e "\nFile permissions:"
find "$DB_PATH" -type f -exec ls -l {} \; | head -10

echo -e "\n=== Checking if original ChromaDB is in use ==="
lsof | grep -i chroma | head -10

echo -e "\n=== Checking disk space ==="
df -h "$DB_PATH"

echo -e "\n=== ChromaDB file structure ==="
find "$DB_PATH" -type f -name "*.sqlite3" -o -name "*.parquet" | head -20
