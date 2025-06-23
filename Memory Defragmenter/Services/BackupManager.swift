//
//  BackupManager.swift
//  Memory Defragmenter
//
//  Created by Nicholas Rogers on 11.06.2025.
//

import Foundation
import CryptoKit
import Compression

// MARK: - Backup Error Types
enum BackupError: LocalizedError {
    case notFound
    case checksumMismatch
    case compressionFailed
    case decompressionFailed
    case insufficientSpace
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Backup not found"
        case .checksumMismatch:
            return "Backup integrity check failed - file may be corrupted"
        case .compressionFailed:
            return "Failed to compress backup"
        case .decompressionFailed:
            return "Failed to decompress backup"
        case .insufficientSpace:
            return "Insufficient disk space for backup"
        }
    }
}

// MARK: - Backup Manager
actor BackupManager {
    private let backupDirectory: URL
    private let fileManager = FileManager.default
    
    init() throws {
        // Create backup directory in Application Support
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.backupDirectory = appSupport.appendingPathComponent("MemoryDefragmenter/Backups")
        
        // Create directory if it doesn't exist
        try fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Backup Creation
    func createBackup(of database: URL) async throws -> BackupInfo {
        // Check available space
        try await verifyAvailableSpace(for: database)
        
        // Generate backup filename
        let timestampString = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: ".", with: "-")
        let backupName = "memory_backup_\(timestampString).db"
        let backupPath = backupDirectory.appendingPathComponent(backupName)
        
        // Create backup
        try fileManager.copyItem(at: database, to: backupPath)
        
        // Count memories before compression
        let memoryCount = try await countMemoriesInDatabase(at: backupPath)
        
        // Compress backup
        let compressedPath = try await compressBackup(backupPath)
        
        // Remove uncompressed backup
        try fileManager.removeItem(at: backupPath)
        
        // Generate checksum
        let checksum = try await calculateChecksum(for: compressedPath)
        
        // Get file size
        let attributes = try fileManager.attributesOfItem(atPath: compressedPath.path)
        let sizeBytes = attributes[.size] as? Int64 ?? 0
        
        // Create backup info
        let info = BackupInfo(
            id: UUID(),
            timestamp: Date(),
            originalPath: database.path,
            backupPath: compressedPath.path,
            checksum: checksum,
            memoryCount: memoryCount,
            sizeBytes: sizeBytes
        )
        
        // Save backup metadata
        try await saveBackupInfo(info)
        
        #if DEBUG
        print("Created backup: \\(info.id)")
        print("Size: \\(info.formattedSize)")
        print("Memories: \\(info.memoryCount)")
        #endif
        
        return info
    }
    
    // MARK: - Backup Restoration
    func restoreBackup(_ backupId: UUID) async throws {
        guard let backup = try await loadBackupInfo(backupId) else {
            throw BackupError.notFound
        }
        
        let backupURL = URL(fileURLWithPath: backup.backupPath)
        
        // Verify checksum
        let currentChecksum = try await calculateChecksum(for: backupURL)
        guard currentChecksum == backup.checksum else {
            throw BackupError.checksumMismatch
        }
        
        // Decompress backup
        let decompressed = try await decompressBackup(backupURL)
        
        // Replace original database
        let originalURL = URL(fileURLWithPath: backup.originalPath)
        
        // Create a temporary backup of current database
        let tempBackup = originalURL.appendingPathExtension("tmp")
        try fileManager.copyItem(at: originalURL, to: tempBackup)
        
        do {
            // Remove current database
            try fileManager.removeItem(at: originalURL)
            
            // Move decompressed backup to original location
            try fileManager.moveItem(at: decompressed, to: originalURL)
            
            // Remove temporary backup
            try fileManager.removeItem(at: tempBackup)
            
        } catch {
            // Restore from temporary backup if something went wrong
            if fileManager.fileExists(atPath: tempBackup.path) {
                try? fileManager.removeItem(at: originalURL)
                try? fileManager.moveItem(at: tempBackup, to: originalURL)
            }
            throw error
        }
    }
    
    // MARK: - Backup Management
    func listBackups() async throws -> [BackupInfo] {
        let metadataPath = backupDirectory.appendingPathComponent("backups.json")
        
        guard fileManager.fileExists(atPath: metadataPath.path) else {
            return []
        }
        
        let data = try Data(contentsOf: metadataPath)
        let backups = try JSONDecoder().decode([BackupInfo].self, from: data)
        
        // Filter out backups whose files no longer exist
        return backups.filter { backup in
            fileManager.fileExists(atPath: backup.backupPath)
        }
    }
    
    func deleteBackup(_ backupId: UUID) async throws {
        var backups = try await listBackups()
        
        guard let index = backups.firstIndex(where: { $0.id == backupId }) else {
            throw BackupError.notFound
        }
        
        let backup = backups[index]
        
        // Delete backup file
        try fileManager.removeItem(atPath: backup.backupPath)
        
        // Update metadata
        backups.remove(at: index)
        try await saveBackupList(backups)
    }
    
    func cleanupOldBackups(keepLast: Int = 10) async throws {
        var backups = try await listBackups()
        
        // Sort by timestamp, newest first
        backups.sort { $0.timestamp > $1.timestamp }
        
        // Keep only the specified number of backups
        if backups.count > keepLast {
            let toDelete = backups[keepLast...]
            
            for backup in toDelete {
                try await deleteBackup(backup.id)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func verifyAvailableSpace(for database: URL) async throws {
        let attributes = try fileManager.attributesOfItem(atPath: database.path)
        let dbSize = attributes[.size] as? Int64 ?? 0
        
        // Check for at least 2x database size (for backup + compression overhead)
        let requiredSpace = dbSize * 2
        
        let availableSpace = try getAvailableDiskSpace()
        
        guard availableSpace > requiredSpace else {
            throw BackupError.insufficientSpace
        }
    }
    
    private func getAvailableDiskSpace() throws -> Int64 {
        let attributes = try fileManager.attributesOfFileSystem(forPath: backupDirectory.path)
        return attributes[.systemFreeSize] as? Int64 ?? 0
    }
    
    private func compressBackup(_ url: URL) async throws -> URL {
        let compressedPath = url.appendingPathExtension("gz")
        
        guard let sourceData = try? Data(contentsOf: url) else {
            throw BackupError.compressionFailed
        }
        
        // Compress data
        let compressedData = sourceData.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return Data() }
            
            let sourceBuffer = baseAddress.assumingMemoryBound(to: UInt8.self)
            let sourceSize = sourceData.count
            let destSize = sourceSize + 512 // Add some buffer
            let destBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destSize)
            defer { destBuffer.deallocate() }
            
            let compressedSize = compression_encode_buffer(
                destBuffer, destSize,
                sourceBuffer, sourceSize,
                nil, COMPRESSION_ZLIB
            )
            
            guard compressedSize > 0 else { return Data() }
            return Data(bytes: destBuffer, count: compressedSize)
        }
        
        guard !compressedData.isEmpty else {
            throw BackupError.compressionFailed
        }
        
        try compressedData.write(to: compressedPath)
        return compressedPath
    }
    
    private func decompressBackup(_ url: URL) async throws -> URL {
        let decompressedPath = url.deletingPathExtension()
        
        guard let compressedData = try? Data(contentsOf: url) else {
            throw BackupError.decompressionFailed
        }
        
        // Decompress data
        let decompressedData = compressedData.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return Data() }
            
            let sourceBuffer = baseAddress.assumingMemoryBound(to: UInt8.self)
            let sourceSize = compressedData.count
            let destSize = sourceSize * 4 // Assume up to 4x expansion
            let destBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destSize)
            defer { destBuffer.deallocate() }
            
            let decompressedSize = compression_decode_buffer(
                destBuffer, destSize,
                sourceBuffer, sourceSize,
                nil, COMPRESSION_ZLIB
            )
            
            guard decompressedSize > 0 else { return Data() }
            return Data(bytes: destBuffer, count: decompressedSize)
        }
        
        guard !decompressedData.isEmpty else {
            throw BackupError.decompressionFailed
        }
        
        try decompressedData.write(to: decompressedPath)
        return decompressedPath
    }
    
    private func calculateChecksum(for url: URL) async throws -> String {
        let data = try Data(contentsOf: url)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func countMemoriesInDatabase(at url: URL) async throws -> Int {
        let db = MemoryDatabase(path: url.path)
        try await db.connect()
        defer {
            Task {
                await db.disconnect()
            }
        }
        
        return try await db.countMemories()
    }
    
    private func saveBackupInfo(_ info: BackupInfo) async throws {
        var backups = try await listBackups()
        backups.append(info)
        try await saveBackupList(backups)
    }
    
    private func saveBackupList(_ backups: [BackupInfo]) async throws {
        let metadataPath = backupDirectory.appendingPathComponent("backups.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(backups)
        try data.write(to: metadataPath)
    }
    
    private func loadBackupInfo(_ id: UUID) async throws -> BackupInfo? {
        let backups = try await listBackups()
        return backups.first { $0.id == id }
    }
    
    // MARK: - Verification
    func verifyBackupDirectory() throws {
        guard fileManager.fileExists(atPath: backupDirectory.path) else {
            try fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
            return
        }
        
        // Check if we can write to the directory
        let testFile = backupDirectory.appendingPathComponent(".write_test")
        try "test".write(to: testFile, atomically: true, encoding: .utf8)
        try fileManager.removeItem(at: testFile)
    }
}



