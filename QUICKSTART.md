# Quick Start Guide - Memory Defragmenter

## Important: ChromaDB Cannot Be Opened Directly!

Memory Defragmenter works with SQLite databases, not ChromaDB directly. You must use the export/import workflow.

## Step-by-Step Instructions:

### 1. Export ChromaDB to SQLite
Open Terminal and run:
```bash
cd "/Users/rogers/GitHub/Memory Defragmenter"
./scripts/chromadb_workflow.sh
```

This creates `memory_export.db` in your current directory.

### 2. Open in Memory Defragmenter
- Open Memory Defragmenter app
- Click "Select ChromaDB" 
- Select the `memory_export.db` FILE (not a folder)
- Run analysis
- Optimize

### 3. Import Back
The workflow script will guide you through importing the optimized database back to ChromaDB.

## File Locations:
- ChromaDB: `/Users/rogers/GitHub/mcp-memory-data/chroma_db/`
- Export file: `memory_export.db` (in Memory Defragmenter directory)
- Backups: `/Users/rogers/GitHub/mcp-memory-data/backups/`

## Troubleshooting:
- If you see "unable to open database file", you're trying to open ChromaDB directly
- Always use the export workflow first
- The app works with `.db` files, not ChromaDB directories
