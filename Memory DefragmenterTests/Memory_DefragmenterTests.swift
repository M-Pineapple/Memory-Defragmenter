//
//  Memory_DefragmenterTests.swift
//  Memory DefragmenterTests
//
//  Created by Pineapple 🍍 on 11.06.2025.
//

import XCTest
@testable import Memory_Defragmenter

final class Memory_DefragmenterTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testModelCreation() throws {
        // Test MemoryRecord creation
        let record = MemoryRecord(
            id: "test-1",
            content: "Test memory content",
            embedding: [0.1, 0.2, 0.3],
            metadata: ["key": "value"],
            timestamp: Date(),
            contentHash: "hash123"
        )
        
        XCTAssertEqual(record.id, "test-1")
        XCTAssertEqual(record.content, "Test memory content")
        XCTAssertEqual(record.embedding.count, 3)
    }
    
    func testClusterCreation() throws {
        // Test MemoryCluster creation
        let memory1 = MemoryRecord(
            id: "test-1",
            content: "First memory",
            embedding: [0.1, 0.2, 0.3],
            metadata: [:],
            timestamp: Date(),
            contentHash: "hash1"
        )
        
        let memory2 = MemoryRecord(
            id: "test-2",
            content: "Second memory",
            embedding: [0.1, 0.2, 0.3],
            metadata: [:],
            timestamp: Date(),
            contentHash: "hash2"
        )
        
        let cluster = MemoryCluster(
            memories: [memory1, memory2],
            similarity: 0.95,
            suggestedMerge: "Consolidated memory",
            preservedMetadata: [:]
        )
        
        XCTAssertEqual(cluster.memories.count, 2)
        XCTAssertEqual(cluster.similarity, 0.95)
        XCTAssertEqual(cluster.savingsPercentage, 50)
    }
    
    func testBackupInfo() throws {
        // Test BackupInfo creation and formatting
        let backup = BackupInfo(
            id: UUID(),
            timestamp: Date(),
            originalPath: "/path/to/db.sqlite",
            backupPath: "/path/to/backup.gz",
            checksum: "checksum123",
            memoryCount: 1000,
            sizeBytes: 1_048_576 // 1 MB
        )
        
        XCTAssertEqual(backup.memoryCount, 1000)
        XCTAssertEqual(backup.formattedSize, "1 MB")
    }
}
