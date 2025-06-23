-- Test Memory Database for Memory Defragmenter
-- Creates a simple memory database with some duplicate entries

-- Create the main memories table
CREATE TABLE IF NOT EXISTS memories (
    id TEXT PRIMARY KEY,
    content TEXT NOT NULL,
    embedding TEXT, -- JSON array of floats
    metadata TEXT,  -- JSON object
    timestamp REAL,
    content_hash TEXT
);

-- Insert some test memories with duplicates
-- Group 1: Python programming memories (3 similar entries)
INSERT INTO memories VALUES 
('mem-001', 'User prefers Python for data science projects', '[0.1, 0.2, 0.3, 0.4, 0.5]', '{"category": "programming"}', 1704067200, 'hash001'),
('mem-002', 'Nicholas likes using Python for data analysis', '[0.1, 0.2, 0.3, 0.4, 0.5]', '{"category": "programming"}', 1704153600, 'hash002'),
('mem-003', 'Python is the preferred language for data science', '[0.1, 0.2, 0.3, 0.4, 0.5]', '{"category": "programming"}', 1704240000, 'hash003');

-- Group 2: Swift development memories (2 similar entries)
INSERT INTO memories VALUES 
('mem-004', 'User is learning Swift for iOS development', '[0.5, 0.4, 0.3, 0.2, 0.1]', '{"category": "programming"}', 1704326400, 'hash004'),
('mem-005', 'Nicholas is developing iOS apps with Swift', '[0.5, 0.4, 0.3, 0.2, 0.1]', '{"category": "programming"}', 1704412800, 'hash005');

-- Group 3: Memory MCP memories (3 similar entries)
INSERT INTO memories VALUES 
('mem-006', 'Memory MCP needs defragmentation functionality', '[0.3, 0.3, 0.3, 0.3, 0.3]', '{"category": "tools"}', 1704499200, 'hash006'),
('mem-007', 'The Memory MCP database has duplicate entries', '[0.3, 0.3, 0.3, 0.3, 0.3]', '{"category": "tools"}', 1704585600, 'hash007'),
('mem-008', 'Memory MCP database requires optimization', '[0.3, 0.3, 0.3, 0.3, 0.3]', '{"category": "tools"}', 1704672000, 'hash008');

-- Some unique memories (no duplicates)
INSERT INTO memories VALUES 
('mem-009', 'User lives in Geneva, Switzerland', '[0.7, 0.1, 0.1, 0.1, 0.0]', '{"category": "personal"}', 1704758400, 'hash009'),
('mem-010', 'Has Mauritian heritage', '[0.8, 0.1, 0.1, 0.0, 0.0]', '{"category": "personal"}', 1704844800, 'hash010');

-- Create an index for faster queries
CREATE INDEX idx_memories_timestamp ON memories(timestamp);
CREATE INDEX idx_memories_content_hash ON memories(content_hash);
