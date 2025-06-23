#!/usr/bin/env python3

import chromadb
import sys
import os

# Try to open in read-only mode
db_path = "/Users/rogers/GitHub/mcp-memory-data/chroma_db"

print(f"Opening ChromaDB in read-only mode from: {db_path}")

try:
    # Set environment variable for read-only mode
    os.environ['CHROMA_DB_IMPL'] = 'duckdb+parquet'
    
    client = chromadb.PersistentClient(path=db_path)
    collection = client.get_collection("memory_collection")
    
    print("Counting memories...")
    count = collection.count()
    print(f"Total memories: {count}")
    
    # Get a sample
    print("\nGetting first 5 memories...")
    results = collection.get(limit=5)
    
    for i, doc in enumerate(results['documents'][:3]):
        print(f"\nMemory {i+1}: {doc[:100]}...")
        
except Exception as e:
    print(f"Error: {e}")
    print("\nTrying alternative approach...")
    
    # Try direct SQLite access
    import sqlite3
    db_file = os.path.join(db_path, "chroma.sqlite3")
    
    if os.path.exists(db_file):
        print(f"Found SQLite file: {db_file}")
        conn = sqlite3.connect(f"file:{db_file}?mode=ro", uri=True)
        cursor = conn.cursor()
        
        # Check tables
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = cursor.fetchall()
        print(f"Tables: {tables}")
        
        conn.close()
