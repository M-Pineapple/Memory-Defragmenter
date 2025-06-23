//
//  Models.swift
//  Memory Defragmenter
//
//  Created by Nicholas Rogers on 11.06.2025.
//

import Foundation

// MARK: - Memory Record
struct MemoryRecord: Identifiable, Codable {
    let id: String
    let content: String
    let embedding: [Float]
    let metadata: [String: String]
    let timestamp: Date
    let contentHash: String
    
    nonisolated var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

// MARK: - Memory Cluster
struct MemoryCluster: Identifiable {
    let id = UUID()
    let memories: [MemoryRecord]
    let similarity: Float
    let suggestedMerge: String
    let preservedMetadata: [String: String]
    
    var savingsPercentage: Int {
        let originalCount = memories.count
        let finalCount = 1
        return Int(((Double(originalCount - finalCount) / Double(originalCount)) * 100))
    }
    
    var oldestMemory: MemoryRecord? {
        memories.min(by: { $0.timestamp < $1.timestamp })
    }
    
    var newestMemory: MemoryRecord? {
        memories.max(by: { $0.timestamp < $1.timestamp })
    }
}

// MARK: - Analysis Result
struct AnalysisResult {
    let totalMemories: Int
    let duplicateClusters: [MemoryCluster]
    let potentialSavings: Int
    let recommendations: [Recommendation]
    let timestamp: Date = Date()
    
    var totalDuplicates: Int {
        duplicateClusters.reduce(0) { $0 + $1.memories.count - 1 }
    }
    
    var clusterSizes: [(id: String, size: Int, type: String)] {
        duplicateClusters.enumerated().map { index, cluster in
            (id: "Cluster \\(index + 1)", 
             size: cluster.memories.count,
             type: cluster.similarity > 0.9 ? "Exact" : "Similar")
        }
    }
}

// MARK: - Recommendation
struct Recommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let title: String
    let description: String
    let impact: Impact
}

enum RecommendationType {
    case merge
    case archive
    case reorganize
    case review
}

enum Impact {
    case high
    case medium
    case low
    
    var color: String {
        switch self {
        case .high: return "red"
        case .medium: return "orange"
        case .low: return "yellow"
        }
    }
}

// MARK: - Backup Info
struct BackupInfo: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let originalPath: String
    let backupPath: String
    let checksum: String
    let memoryCount: Int
    let sizeBytes: Int64
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: sizeBytes)
    }
}

// MARK: - Optimization Options
struct OptimizationOptions {
    let approvedClusters: Set<UUID>
    let preserveMetadata: Bool
    let createAuditTrail: Bool
    let dryRun: Bool = false
}

// MARK: - Database Statistics
struct DatabaseStatistics {
    let totalMemories: Int
    let totalSize: Int64
    let averageMemorySize: Int
    let oldestMemory: Date?
    let newestMemory: Date?
    let topTags: [(tag: String, count: Int)]
}
