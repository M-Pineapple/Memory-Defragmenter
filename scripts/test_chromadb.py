#!/usr/bin/env python3

import chromadb
import sys

# Test script to see how many memories are in the ChromaDB
db_path = sys.argv[1] if len(sys.argv) > 1 else "/Users/rogers/Desktop/chroma_db"

print(f"Loading ChromaDB from: {db_path}")
client = chromadb.PersistentClient(path=db_path)

print("Getting collection...")
collection = client.get_collection("memory_collection")

print("Counting memories...")
count = collection.count()
print(f"Total memories: {count}")

# Try to get just a few memories
print("Getting first 10 memories...")
results = collection.get(limit=10, include=["metadatas", "documents"])
print(f"Retrieved {len(results['ids'])} memories")

for i, doc_id in enumerate(results['ids'][:3]):
    print(f"Memory {i+1}: {results['documents'][i][:100]}...")
