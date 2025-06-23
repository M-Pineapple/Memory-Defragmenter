//
//  MemoryDatabase.swift
//  Memory Defragmenter
//
//  Created by Nicholas Rogers on 11.06.2025.
//

import Foundation
import SQLite3

// SQLite transient destructor for text binding
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

// MARK: - Database Error Types
enum DatabaseError: LocalizedError {
    case connectionFailed(String)
    case incompatibleSchema
    case missingColumn(String)
    case queryFailed(String)
    case transactionFailed(String)
    case databaseLocked
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed(let message):
            return "Failed to connect to database: \(message)"
        case .incompatibleSchema:
            return "Database schema is not compatible with Memory MCP"
        case .missingColumn(let column):
            return "Required column missing: \(column)"
        case .queryFailed(let message):
            return "Database query failed: \(message)"
        case .transactionFailed(let reason):
            return "Transaction failed: \(reason)"
        case .databaseLocked:
            return "Database is locked by another process"
        }
    }
}

// MARK: - Memory Database
actor MemoryDatabase {
    private var db: OpaquePointer?
    private let dbPath: String
    
    init(path: String) {
        self.dbPath = path
    }
    
    // MARK: - Connection Management
    func connect() async throws {
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.connectionFailed(errorMessage)
        }
        
        // Enable foreign keys
        try await execute("PRAGMA foreign_keys = ON")
        
        // Check if database is writable
        let fileManager = FileManager.default
        if !fileManager.isWritableFile(atPath: dbPath) {
            print("WARNING: Database is not writable at path: \(dbPath)")
            // Try to make it writable
            try? fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: dbPath)
        }
        
        // Verify schema compatibility
        try await verifySchema()
        
        #if DEBUG
        print("Successfully connected to database: \(dbPath)")
        print("Database is writable: \(fileManager.isWritableFile(atPath: dbPath))")
        #endif
    }
    
    func disconnect() async {
        if let db = db {
            sqlite3_close(db)
            self.db = nil
        }
    }
    
    // MARK: - Schema Verification
    private func verifySchema() async throws {
        let tables = try await getTables()
        
        // Check for memory table (could be 'memories' or similar)
        let memoryTableNames = ["memories", "memory", "knowledge_graph"]
        let foundTable = tables.first { memoryTableNames.contains($0.lowercased()) }
        
        guard let tableName = foundTable else {
            throw DatabaseError.incompatibleSchema
        }
        
        // Verify required columns
        let columns = try await getColumns(for: tableName)
        let requiredColumns = ["content", "embedding"]
        
        for required in requiredColumns {
            if !columns.contains(where: { $0.lowercased().contains(required.lowercased()) }) {
                throw DatabaseError.missingColumn(required)
            }
        }
        
        #if DEBUG
        print("Schema verified. Using table: \(tableName)")
        print("Available columns: \(columns)")
        #endif
    }
    
    // MARK: - Database Queries
    func loadAllMemories() async throws -> [MemoryRecord] {
        // First, determine the correct table name
        let tables = try await getTables()
        let memoryTable = tables.first { ["memories", "memory", "knowledge_graph"].contains($0.lowercased()) } ?? "memories"
        
        let query = """
            SELECT id, content, embedding, metadata, timestamp, content_hash
            FROM \(memoryTable)
            ORDER BY timestamp DESC
        """
        
        var memories: [MemoryRecord] = []
        
        try await withStatement(query) { statement in
            while sqlite3_step(statement) == SQLITE_ROW {
                let memory = try parseMemoryRecord(from: statement)
                memories.append(memory)
            }
        }
        
        return memories
    }
    
    func countMemories() async throws -> Int {
        let tables = try await getTables()
        let memoryTable = tables.first { ["memories", "memory", "knowledge_graph"].contains($0.lowercased()) } ?? "memories"
        
        let query = "SELECT COUNT(*) FROM \(memoryTable)"
        var count = 0
        
        try await withStatement(query) { statement in
            if sqlite3_step(statement) == SQLITE_ROW {
                count = Int(sqlite3_column_int(statement, 0))
            }
        }
        
        return count
    }
    
    // MARK: - Transaction Management
    func beginTransaction() async throws {
        try await execute("BEGIN TRANSACTION")
    }
    
    func commitTransaction() async throws {
        try await execute("COMMIT")
    }
    
    func rollbackTransaction() async throws {
        try await execute("ROLLBACK")
    }
    
    // MARK: - Update Operations
    func updateMemory(id: String, content: String, metadata: [String: String]) async throws {
        let tables = try await getTables()
        let memoryTable = tables.first { ["memories", "memory", "knowledge_graph"].contains($0.lowercased()) } ?? "memories"
        
        // Check what columns we actually have
        let columns = try await getColumns(for: memoryTable)
        print("Available columns in \(memoryTable): \(columns)")
        
        let metadataJSON = try JSONSerialization.data(withJSONObject: metadata, options: [])
        let metadataString = String(data: metadataJSON, encoding: .utf8) ?? "{}"
        
        let query = """
            UPDATE \(memoryTable)
            SET content = ?, metadata = ?, timestamp = ?
            WHERE id = ?
        """
        
        try await withStatement(query) { statement in
            sqlite3_bind_text(statement, 1, content, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, metadataString, -1, SQLITE_TRANSIENT)
            sqlite3_bind_double(statement, 3, Date().timeIntervalSince1970)
            sqlite3_bind_text(statement, 4, id, -1, SQLITE_TRANSIENT)
            
            guard sqlite3_step(statement) == SQLITE_DONE else {
                let errorCode = sqlite3_errcode(self.db)
                let errorMessage = String(cString: sqlite3_errmsg(self.db))
                print("UPDATE FAILED - Error code: \(errorCode), Message: \(errorMessage)")
                print("Query: \(query)")
                print("Parameters: id=\(id), content=\(content)")
                throw DatabaseError.queryFailed("Failed to update memory: \(errorMessage)")
            }
        }
    }
    
    func deleteMemory(_ id: String) async throws {
        let tables = try await getTables()
        let memoryTable = tables.first { ["memories", "memory", "knowledge_graph"].contains($0.lowercased()) } ?? "memories"
        
        let query = "DELETE FROM \(memoryTable) WHERE id = ?"
        
        try await withStatement(query) { statement in
            sqlite3_bind_text(statement, 1, id, -1, SQLITE_TRANSIENT)
            
            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw DatabaseError.queryFailed("Failed to delete memory")
            }
        }
    }
    
    func archiveMemory(_ memory: MemoryRecord) async throws {
        // Create archive table if it doesn't exist
        try await createArchiveTableIfNeeded()
        
        let query = """
            INSERT INTO memory_archive (original_id, content, embedding, metadata, timestamp, archived_at)
            VALUES (?, ?, ?, ?, ?, ?)
        """
        
        let metadataJSON = try JSONSerialization.data(withJSONObject: memory.metadata, options: [])
        let metadataString = String(data: metadataJSON, encoding: .utf8) ?? "{}"
        let embeddingData = try JSONSerialization.data(withJSONObject: memory.embedding, options: [])
        
        try await withStatement(query) { statement in
            sqlite3_bind_text(statement, 1, memory.id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, memory.content, -1, SQLITE_TRANSIENT)
            sqlite3_bind_blob(statement, 3, (embeddingData as NSData).bytes, Int32(embeddingData.count), SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 4, metadataString, -1, SQLITE_TRANSIENT)
            sqlite3_bind_double(statement, 5, memory.timestamp.timeIntervalSince1970)
            sqlite3_bind_double(statement, 6, Date().timeIntervalSince1970)
            
            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw DatabaseError.queryFailed("Failed to archive memory")
            }
        }
    }
    
    // MARK: - Maintenance Operations
    func rebuildIndexes() async throws {
        try await execute("REINDEX")
    }
    
    func vacuum() async throws {
        try await execute("VACUUM")
    }
    
    func integrityCheck() async throws {
        let result = try await queryScalar("PRAGMA integrity_check")
        guard result == "ok" else {
            throw DatabaseError.queryFailed("Database integrity check failed: \\(result)")
        }
    }
    
    func isLocked() async throws -> Bool {
        // Try to acquire an exclusive lock
        do {
            try await execute("BEGIN EXCLUSIVE TRANSACTION")
            try await execute("ROLLBACK")
            return false
        } catch {
            return true
        }
    }
    
    // MARK: - Helper Methods
    private func getTables() async throws -> [String] {
        let query = "SELECT name FROM sqlite_master WHERE type='table'"
        var tables: [String] = []
        
        try await withStatement(query) { statement in
            while sqlite3_step(statement) == SQLITE_ROW {
                if let name = sqlite3_column_text(statement, 0) {
                    tables.append(String(cString: name))
                }
            }
        }
        
        return tables
    }
    
    private func getColumns(for table: String) async throws -> [String] {
        let query = "PRAGMA table_info(\(table))"
        var columns: [String] = []
        
        try await withStatement(query) { statement in
            while sqlite3_step(statement) == SQLITE_ROW {
                if let name = sqlite3_column_text(statement, 1) {
                    columns.append(String(cString: name))
                }
            }
        }
        
        return columns
    }
    
    private func createArchiveTableIfNeeded() async throws {
        let query = """
            CREATE TABLE IF NOT EXISTS memory_archive (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                original_id TEXT NOT NULL,
                content TEXT NOT NULL,
                embedding BLOB,
                metadata TEXT,
                timestamp REAL,
                archived_at REAL NOT NULL
            )
        """
        
        try await execute(query)
    }
    
    private func execute(_ query: String) async throws {
        try await withStatement(query) { statement in
            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw DatabaseError.queryFailed(query)
            }
        }
    }
    
    private func queryScalar(_ query: String) async throws -> String {
        var result = ""
        
        try await withStatement(query) { statement in
            if sqlite3_step(statement) == SQLITE_ROW {
                if let text = sqlite3_column_text(statement, 0) {
                    result = String(cString: text)
                }
            }
        }
        
        return result
    }
    
    private func withStatement<T>(_ query: String, action: (OpaquePointer) async throws -> T) async throws -> T {
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed(errorMessage)
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        return try await action(statement!)
    }
    
    private func parseMemoryRecord(from statement: OpaquePointer) throws -> MemoryRecord {
        // Parse ID
        let id = String(cString: sqlite3_column_text(statement, 0))
        
        // Parse content
        let content = String(cString: sqlite3_column_text(statement, 1))
        
        // Parse embedding (stored as JSON array or blob)
        var embedding: [Float] = []
        if let embeddingBlob = sqlite3_column_blob(statement, 2) {
            let embeddingSize = Int(sqlite3_column_bytes(statement, 2))
            let embeddingData = Data(bytes: embeddingBlob, count: embeddingSize)
            
            if let array = try? JSONSerialization.jsonObject(with: embeddingData) as? [Double] {
                embedding = array.map { Float($0) }
            }
        }
        
        // Parse metadata
        var metadata: [String: String] = [:]
        if let metadataText = sqlite3_column_text(statement, 3) {
            let metadataString = String(cString: metadataText)
            if let data = metadataString.data(using: .utf8),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Convert all values to strings
                metadata = dict.reduce(into: [String: String]()) { result, pair in
                    result[pair.key] = "\(pair.value)"
                }
            }
        }
        
        // Parse timestamp
        let timestampInterval = sqlite3_column_double(statement, 4)
        let timestamp = Date(timeIntervalSince1970: timestampInterval)
        
        // Parse content hash
        let contentHash = String(cString: sqlite3_column_text(statement, 5))
        
        return MemoryRecord(
            id: id,
            content: content,
            embedding: embedding,
            metadata: metadata,
            timestamp: timestamp,
            contentHash: contentHash
        )
    }
}
