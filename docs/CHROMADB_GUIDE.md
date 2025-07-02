# Using Memory Defragmenter with ChromaDB (Memory Service MCP)

Memory Defragmenter was originally designed for simple SQLite databases, but Memory Service MCP uses ChromaDB, a more sophisticated vector database. This guide explains how to use Memory Defragmenter with ChromaDB-based Memory Service installations.

## Overview

The process involves three steps:
1. **Export** ChromaDB data to SQLite format
2. **Optimize** using Memory Defragmenter
3. **Import** optimized data back to ChromaDB

## Prerequisites

- Python 3.10+ with ChromaDB installed
- Memory Defragmenter app
- Your Memory Service MCP database location

## Step 1: Export ChromaDB to SQLite

First, install required Python packages:

```bash
pip3 install chromadb sentence-transformers
```

Then run the export script:

```bash
cd "/Users/rogers/GitHub/Memory Defragmenter"
python3 scripts/export_chromadb.py
```

This will create `memory_export.db` in the current directory.

### Custom Paths

If your ChromaDB is in a different location:

```bash
python3 scripts/export_chromadb.py \
  --chroma-path "/path/to/your/chroma_db" \
  --output "my_memories.db"
```

## Step 2: Optimize with Memory Defragmenter

1. Open Memory Defragmenter
2. Click "Open Database"
3. Select the exported `memory_export.db` file
4. Click "Start Analysis"
5. Review and select duplicates to consolidate
6. Click "Optimize"

The app will create a backup and optimize the database.

## Step 3: Import Back to ChromaDB

After optimization, import the cleaned data back:

```bash
python3 scripts/import_to_chromadb.py memory_export.db
```

This will:
- Backup your existing ChromaDB (unless --no-backup is used)
- Clear the current ChromaDB
- Import all optimized memories
- Regenerate embeddings if needed

### Custom Import

To specify a different ChromaDB location:

```bash
python3 scripts/import_to_chromadb.py memory_export.db \
  --chroma-path "/path/to/your/chroma_db"
```

To skip backing up (not recommended):

```bash
python3 scripts/import_to_chromadb.py memory_export.db --no-backup
```

## Complete Workflow Example

```bash
# 1. Export ChromaDB to SQLite
python3 scripts/export_chromadb.py

# 2. Open Memory Defragmenter and optimize memory_export.db
# (Use the GUI app)

# 3. Import optimized data back
python3 scripts/import_to_chromadb.py memory_export.db

# 4. Restart Memory Service MCP to use the optimized database
```

## Important Notes

### Embeddings
- ChromaDB stores embeddings separately from the SQLite metadata
- During export, embeddings are preserved in the SQLite file
- During import, if embeddings are missing, ChromaDB will regenerate them
- This may take time for large databases

### Backups
- **Automatic backups**: While the Memory Service documentation mentions automatic backups every 24 hours, this feature may not be fully implemented
- **Manual backups**: Use the provided backup script: `python scripts/backup_memories.py` in the Memory Service directory
- **Our workflow**: The ChromaDB workflow script automatically creates a manual backup before export
- The export script doesn't modify your original ChromaDB
- The import script creates a timestamped backup by default
- Memory Defragmenter also creates its own backups
- Keep these backups until you're sure everything works correctly

### Compatibility
- This process works with Memory Service MCP v0.2.0 and later
- The scripts assume the standard ChromaDB collection name: "memory_collection"
- Custom metadata fields are preserved during the round-trip

### Performance
- Export/import can be slow for large databases (>10,000 memories)
- ChromaDB needs to regenerate its index after import
- First queries after import may be slower while the index rebuilds

## Troubleshooting

### "ChromaDB collection not found"
The collection name might be different. Check your Memory Service configuration.

### "No embedding function available"
Install sentence-transformers: `pip3 install sentence-transformers`

### "Import failed with embedding errors"
Let ChromaDB regenerate embeddings by using the import script without embeddings.

### Memory Service not working after import
1. Check that the ChromaDB path is correct
2. Ensure Memory Service MCP is stopped during import
3. Restart Memory Service MCP after import
4. Check Memory Service logs for errors

## Alternative: Direct ChromaDB Support

For frequent use, consider modifying Memory Defragmenter to support ChromaDB directly. This would eliminate the export/import steps but requires significant code changes to handle:
- ChromaDB's client API
- Vector similarity calculations
- Embedding management
- Collection operations

## Safety First

Always:
1. Stop Memory Service MCP before import
2. Keep all backups until verified working
3. Test with a small subset first
4. Monitor Memory Service logs after import

Remember: Memory Defragmenter's optimization is valuable even with the extra export/import steps, especially for databases with many duplicates or fragmented information.
