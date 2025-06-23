#!/usr/bin/env python3
"""
Import optimized SQLite data back to ChromaDB
"""

import sqlite3
import json
import os
import sys
import shutil
from pathlib import Path
import chromadb
from chromadb.utils import embedding_functions
import argparse
from datetime import datetime
import time

def import_sqlite_to_chroma(sqlite_path, chroma_path, backup=True):
    """Import SQLite data back to ChromaDB"""
    
    print(f"Loading SQLite database: {sqlite_path}")
    
    # Verify SQLite file exists
    if not os.path.exists(sqlite_path):
        print(f"Error: SQLite file not found: {sqlite_path}")
        return False
    
    # Backup existing ChromaDB if requested
    if backup and os.path.exists(chroma_path):
        backup_path = f"{chroma_path}_backup_{int(time.time())}"
        print(f"Backing up existing ChromaDB to: {backup_path}")
        shutil.copytree(chroma_path, backup_path)
    
    # Load memories from SQLite
    conn = sqlite3.connect(sqlite_path)
    cursor = conn.cursor()
    
    # Check if this is an optimized database (has the archive table)
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='memory_archive'")
    has_archive = cursor.fetchone() is not None
    
    if has_archive:
        print("Detected optimized database with archive table")
    
    # Get all memories
    cursor.execute('''
    SELECT id, content, embedding, metadata, timestamp, content_hash
    FROM memories
    ORDER BY timestamp
    ''')
    
    memories = cursor.fetchall()
    conn.close()
    
    print(f"Found {len(memories)} memories to import")
    
    # Initialize ChromaDB
    print(f"Initializing ChromaDB at: {chroma_path}")
    
    # Clear existing ChromaDB
    if os.path.exists(chroma_path):
        print("Clearing existing ChromaDB data...")
        shutil.rmtree(chroma_path)
    
    # Create new ChromaDB client
    client = chromadb.PersistentClient(path=chroma_path)
    
    # Use the same embedding function as Memory Service
    embedding_function = embedding_functions.SentenceTransformerEmbeddingFunction(
        model_name="all-MiniLM-L6-v2",
        device="cpu"  # Use CPU for compatibility
    )
    
    # Create collection
    collection = client.create_collection(
        name="memory_collection",
        metadata={"hnsw:space": "cosine"},
        embedding_function=embedding_function
    )
    
    print("Importing memories to ChromaDB...")
    
    # Prepare batch data
    ids = []
    documents = []
    metadatas = []
    embeddings = []
    
    for i, (memory_id, content, embedding_json, metadata_json, timestamp, content_hash) in enumerate(memories):
        # Parse metadata
        try:
            metadata = json.loads(metadata_json) if metadata_json else {}
        except json.JSONDecodeError:
            metadata = {}
        
        # Add required fields to metadata
        metadata["content_hash"] = content_hash
        metadata["timestamp"] = int(timestamp)
        metadata["timestamp_float"] = float(timestamp)
        metadata["created_at"] = float(timestamp)
        
        # Parse embedding if available
        try:
            embedding = json.loads(embedding_json) if embedding_json else None
        except json.JSONDecodeError:
            embedding = None
        
        # Add to batch
        ids.append(memory_id)
        documents.append(content)
        metadatas.append(metadata)
        if embedding and len(embedding) > 0:
            embeddings.append(embedding)
        
        # Add in batches of 100
        if len(ids) >= 100:
            if embeddings and len(embeddings) == len(ids):
                collection.add(
                    ids=ids,
                    documents=documents,
                    metadatas=metadatas,
                    embeddings=embeddings
                )
            else:
                # Let ChromaDB generate embeddings
                collection.add(
                    ids=ids,
                    documents=documents,
                    metadatas=metadatas
                )
            
            print(f"  Imported {i + 1}/{len(memories)} memories...")
            
            # Clear batch
            ids = []
            documents = []
            metadatas = []
            embeddings = []
    
    # Import remaining memories
    if ids:
        if embeddings and len(embeddings) == len(ids):
            collection.add(
                ids=ids,
                documents=documents,
                metadatas=metadatas,
                embeddings=embeddings
            )
        else:
            collection.add(
                ids=ids,
                documents=documents,
                metadatas=metadatas
            )
    
    print(f"\nSuccessfully imported {len(memories)} memories to ChromaDB")
    
    # Report on archive if present
    if has_archive:
        conn = sqlite3.connect(sqlite_path)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM memory_archive")
        archive_count = cursor.fetchone()[0]
        conn.close()
        
        if archive_count > 0:
            print(f"\nNote: {archive_count} memories were archived during optimization")
            print("These archived memories were not imported back to ChromaDB")
    
    return True

def main():
    parser = argparse.ArgumentParser(description='Import SQLite back to ChromaDB')
    parser.add_argument('sqlite_file', 
                       help='Path to optimized SQLite database')
    parser.add_argument('--chroma-path', 
                       default='/Users/rogers/GitHub/mcp-memory-data/chroma_db',
                       help='Path to ChromaDB directory')
    parser.add_argument('--no-backup', 
                       action='store_true',
                       help='Skip backing up existing ChromaDB')
    
    args = parser.parse_args()
    
    # Import
    success = import_sqlite_to_chroma(
        args.sqlite_file, 
        args.chroma_path, 
        backup=not args.no_backup
    )
    
    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main()
