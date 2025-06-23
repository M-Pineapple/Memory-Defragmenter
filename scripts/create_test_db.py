import sqlite3
import json
import os

# Create test database
db_path = "test_memory.db"

# Remove if exists
if os.path.exists(db_path):
    os.remove(db_path)

# Create connection
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Create table
cursor.execute('''
CREATE TABLE IF NOT EXISTS memories (
    id TEXT PRIMARY KEY,
    content TEXT NOT NULL,
    embedding TEXT,
    metadata TEXT,
    timestamp REAL,
    content_hash TEXT
)
''')

# Test data with similar embeddings for clustering
test_memories = [
    # Python memories (similar embeddings)
    ("mem-001", "User prefers Python for data science projects", [0.1, 0.2, 0.3, 0.4, 0.5], {"category": "programming"}, 1704067200, "hash001"),
    ("mem-002", "Nicholas likes using Python for data analysis", [0.11, 0.21, 0.31, 0.41, 0.51], {"category": "programming"}, 1704153600, "hash002"),
    ("mem-003", "Python is the preferred language for data science", [0.12, 0.22, 0.32, 0.42, 0.52], {"category": "programming"}, 1704240000, "hash003"),
    
    # Swift memories (similar embeddings)
    ("mem-004", "User is learning Swift for iOS development", [0.5, 0.4, 0.3, 0.2, 0.1], {"category": "programming"}, 1704326400, "hash004"),
    ("mem-005", "Nicholas is developing iOS apps with Swift", [0.51, 0.41, 0.31, 0.21, 0.11], {"category": "programming"}, 1704412800, "hash005"),
    
    # Memory MCP memories (similar embeddings)
    ("mem-006", "Memory MCP needs defragmentation functionality", [0.3, 0.3, 0.3, 0.3, 0.3], {"category": "tools"}, 1704499200, "hash006"),
    ("mem-007", "The Memory MCP database has duplicate entries", [0.31, 0.31, 0.31, 0.31, 0.31], {"category": "tools"}, 1704585600, "hash007"),
    ("mem-008", "Memory MCP database requires optimization", [0.32, 0.32, 0.32, 0.32, 0.32], {"category": "tools"}, 1704672000, "hash008"),
    
    # Unique memories
    ("mem-009", "User lives in Geneva, Switzerland", [0.7, 0.1, 0.1, 0.1, 0.0], {"category": "personal"}, 1704758400, "hash009"),
    ("mem-010", "Has Mauritian heritage", [0.8, 0.1, 0.1, 0.0, 0.0], {"category": "personal"}, 1704844800, "hash010"),
]

# Insert data
for memory in test_memories:
    cursor.execute('''
    INSERT INTO memories (id, content, embedding, metadata, timestamp, content_hash)
    VALUES (?, ?, ?, ?, ?, ?)
    ''', (
        memory[0],
        memory[1],
        json.dumps(memory[2]),
        json.dumps(memory[3]),
        memory[4],
        memory[5]
    ))

# Create indexes
cursor.execute('CREATE INDEX idx_memories_timestamp ON memories(timestamp)')
cursor.execute('CREATE INDEX idx_memories_content_hash ON memories(content_hash)')

# Commit and close
conn.commit()
conn.close()

# Make sure the database is writable
os.chmod(db_path, 0o644)

print(f"Test database created: {db_path}")
print("Contains 10 memories with 3 duplicate clusters")
print(f"File permissions: {oct(os.stat(db_path).st_mode)[-3:]}")
