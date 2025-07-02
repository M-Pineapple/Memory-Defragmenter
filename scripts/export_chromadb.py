#!/usr/bin/env python3
"""
Export ChromaDB memories to SQLite format compatible with Memory Defragmenter
"""

import sqlite3
import json
import os
import sys
from pathlib import Path
import chromadb
import argparse
from datetime import datetime

def export_chroma_to_sqlite(chroma_path, output_path):
    """Export ChromaDB data to a simple SQLite database"""
    
    print(f"Loading ChromaDB from: {chroma_path}")
    
    # Initialize ChromaDB client
    try:
        client = chromadb.PersistentClient(path=chroma_path)
        collection = client.get_collection(name="memory_collection")
    except Exception as e:
        print(f"Error loading ChromaDB: {e}")
        return False
    
    # Get all memories from ChromaDB
    print("Fetching all memories from ChromaDB...")
    results = collection.get(
        include=["documents", "metadatas", "embeddings"]
    )
    
    if not results["ids"]:
        print("No memories found in ChromaDB")
        return False
    
    print(f"Found {len(results['ids'])} memories")
    
    # Create SQLite database
    print(f"Creating SQLite database: {output_path}")
    
    # Remove existing file if it exists
    if os.path.exists(output_path):
        os.remove(output_path)
    
    conn = sqlite3.connect(output_path)
    cursor = conn.cursor()
    
    # Create memories table with the structure Memory Defragmenter expects
    cursor.execute('''
    CREATE TABLE memories (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        embedding TEXT,
        metadata TEXT,
        timestamp REAL,
        content_hash TEXT
    )
    ''')
    
    # Create indexes
    cursor.execute('CREATE INDEX idx_memories_timestamp ON memories(timestamp)')
    cursor.execute('CREATE INDEX idx_memories_content_hash ON memories(content_hash)')
    
    # Insert memories
    print("Converting memories...")
    for i in range(len(results["ids"])):
        memory_id = results["ids"][i]
        content = results["documents"][i]
        metadata = results["metadatas"][i]
        
        # Get embedding if available
        embedding = []
        if results.get("embeddings") and i < len(results["embeddings"]):
            embedding = results["embeddings"][i]
        
        # Extract timestamp (try multiple fields)
        timestamp = metadata.get("created_at") or metadata.get("timestamp_float") or metadata.get("timestamp", 0)
        
        # Extract content hash
        content_hash = metadata.get("content_hash", memory_id)
        
        # Convert embedding to JSON string
        embedding_json = json.dumps(embedding) if embedding else "[]"
        
        # Prepare metadata (excluding fields we store separately)
        clean_metadata = {
            k: v for k, v in metadata.items() 
            if k not in ["content_hash", "timestamp", "timestamp_float", "created_at"]
        }
        metadata_json = json.dumps(clean_metadata)
        
        # Insert into SQLite
        cursor.execute('''
        INSERT INTO memories (id, content, embedding, metadata, timestamp, content_hash)
        VALUES (?, ?, ?, ?, ?, ?)
        ''', (
            memory_id,
            content,
            embedding_json,
            metadata_json,
            float(timestamp),
            content_hash
        ))
        
        if (i + 1) % 100 == 0:
            print(f"  Processed {i + 1}/{len(results['ids'])} memories...")
    
    # Commit and close
    conn.commit()
    conn.close()
    
    print(f"\nSuccessfully exported {len(results['ids'])} memories to {output_path}")
    print("\nYou can now open this database with Memory Defragmenter!")
    
    return True

def main():
    parser = argparse.ArgumentParser(description='Export ChromaDB to SQLite for Memory Defragmenter')
    parser.add_argument('--chroma-path', 
                       default='/Users/rogers/GitHub/mcp-memory-data/chroma_db',
                       help='Path to ChromaDB directory')
    parser.add_argument('--output', 
                       default='memory_export.db',
                       help='Output SQLite database path')
    
    args = parser.parse_args()
    
    # Verify ChromaDB path exists
    if not os.path.exists(args.chroma_path):
        print(f"Error: ChromaDB path does not exist: {args.chroma_path}")
        sys.exit(1)
    
    # Export
    success = export_chroma_to_sqlite(args.chroma_path, args.output)
    
    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main()
