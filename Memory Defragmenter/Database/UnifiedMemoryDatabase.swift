//
//  UnifiedMemoryDatabase.swift
//  Memory Defragmenter
//
//  Created by Nicholas Rogers on 21.06.2025.
//

import Foundation

// MARK: - Database Type
enum DatabaseType {
    case sqlite
    case chromaDB
    
    static func detect(from path: String) -> DatabaseType {
        let url = URL(fileURLWithPath: path)
        
        // Check if it's a directory (ChromaDB)
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
           isDirectory.boolValue {
            // Check for ChromaDB structure
            let chromaFiles = ["chroma.sqlite3", "chroma-collections.parquet", "chroma-embeddings.parquet"]
            for file in chromaFiles {
                if FileManager.default.fileExists(atPath: url.appendingPathComponent(file).path) {
                    return .chromaDB
                }
            }
        }
        
        // Default to SQLite for files
        return .sqlite
    }
}

// MARK: - Unified Memory Database
/// Provides a unified interface for both SQLite and ChromaDB databases
class UnifiedMemoryDatabase {
    private let path: String
    private let type: DatabaseType
    private var sqliteDB: MemoryDatabase?
    private var chromaDB: ChromaDBAdapter?
    
    init(path: String) {
        self.path = path
        self.type = DatabaseType.detect(from: path)
        
        switch type {
        case .sqlite:
            self.sqliteDB = MemoryDatabase(path: path)
        case .chromaDB:
            self.chromaDB = ChromaDBAdapter(path: path)
        }
    }
    
    // MARK: - Public Interface
    
    var databaseType: DatabaseType { type }
    
    var typeDescription: String {
        switch type {
        case .sqlite: return "SQLite Database"
        case .chromaDB: return "ChromaDB Vector Database"
        }
    }
    
    func connect() async throws {
        switch type {
        case .sqlite:
            try await sqliteDB?.connect()
        case .chromaDB:
            // ChromaDB doesn't need explicit connection
            break
        }
    }
    
    func disconnect() async {
        switch type {
        case .sqlite:
            await sqliteDB?.disconnect()
        case .chromaDB:
            // ChromaDB doesn't need explicit disconnection
            break
        }
    }
    
    func loadAllMemories() async throws -> [MemoryRecord] {
        switch type {
        case .sqlite:
            guard let db = sqliteDB else { throw DatabaseError.connectionFailed("SQLite not initialized") }
            return try await db.loadAllMemories()
        case .chromaDB:
            guard let db = chromaDB else { throw DatabaseError.connectionFailed("ChromaDB not initialized") }
            return try await db.loadMemories()
        }
    }
    
    func countMemories() async throws -> Int {
        switch type {
        case .sqlite:
            guard let db = sqliteDB else { throw DatabaseError.connectionFailed("SQLite not initialized") }
            return try await db.countMemories()
        case .chromaDB:
            guard let db = chromaDB else { throw DatabaseError.connectionFailed("ChromaDB not initialized") }
            return try await db.countMemories()
        }
    }
    
    func saveOptimizedMemories(_ memories: [MemoryRecord], options: OptimizationOptions) async throws {
        switch type {
        case .sqlite:
            // For SQLite, use the existing transaction-based approach
            guard let db = sqliteDB else { throw DatabaseError.connectionFailed("SQLite not initialized") }
            
            try await db.beginTransaction()
            do {
                // Archive duplicates and update memories
                for memory in memories {
                    if let metadata = memory.metadata["_action"], metadata == "delete" {
                        try await db.archiveMemory(memory)
                        try await db.deleteMemory(memory.id)
                    } else if let metadata = memory.metadata["_action"], metadata == "update" {
                        try await db.updateMemory(
                            id: memory.id,
                            content: memory.content,
                            metadata: memory.metadata.filter { $0.key != "_action" }
                        )
                    }
                }
                try await db.commitTransaction()
            } catch {
                try await db.rollbackTransaction()
                throw error
            }
            
        case .chromaDB:
            // For ChromaDB, replace the entire collection with optimized data
            guard let db = chromaDB else { throw DatabaseError.connectionFailed("ChromaDB not initialized") }
            
            // Filter out memories marked for deletion
            let memoriesToSave = memories.filter { memory in
                memory.metadata["_action"] != "delete"
            }
            
            try await db.saveOptimizedMemories(memoriesToSave, options: options)
        }
    }
    
    // MARK: - Maintenance Operations
    
    func performMaintenance() async throws {
        switch type {
        case .sqlite:
            guard let db = sqliteDB else { return }
            try await db.rebuildIndexes()
            try await db.vacuum()
        case .chromaDB:
            // ChromaDB handles its own maintenance
            break
        }
    }
    
    func integrityCheck() async throws {
        switch type {
        case .sqlite:
            guard let db = sqliteDB else { return }
            try await db.integrityCheck()
        case .chromaDB:
            // Verify ChromaDB can be accessed
            _ = try await countMemories()
        }
    }
}

// MARK: - Optimization Options Extension
extension OptimizationOptions {
    /// Create a save location for the optimized database
    func getSaveLocation(for originalPath: String, type: DatabaseType) -> String {
        let url = URL(fileURLWithPath: originalPath)
        let directory = url.deletingLastPathComponent()
        let name = url.lastPathComponent
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: ".", with: "-")
        
        switch type {
        case .sqlite:
            let newName = name.replacingOccurrences(of: ".db", with: "_optimized_\(timestamp).db")
            return directory.appendingPathComponent(newName).path
        case .chromaDB:
            // For ChromaDB, we modify in place but create a backup
            return originalPath
        }
    }
}
