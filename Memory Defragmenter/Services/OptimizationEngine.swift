//
//  OptimizationEngine.swift
//  Memory Defragmenter
//
//  Created by Pineapple 🍍 on 11.06.2025.
//

import Foundation

// MARK: - Optimization Engine
actor OptimizationEngine {
    
    // MARK: - Main Optimization
    func optimizeDatabase(
        _ database: UnifiedMemoryDatabase,
        clusters: [MemoryCluster],
        options: OptimizationOptions
    ) async throws {
        
        guard !clusters.isEmpty else { return }
        
        // Prepare all memories with optimization actions
        var allMemories = try await database.loadAllMemories()
        var optimizedMemories: [MemoryRecord] = []
        var processedIds = Set<String>()
        
        // Process each approved cluster
        for cluster in clusters {
            if options.approvedClusters.contains(cluster.id) {
                let (merged, toDelete) = try await prepareClusterOptimization(cluster, options: options)
                
                // Add merged memory
                optimizedMemories.append(merged)
                processedIds.insert(merged.id)
                
                // Mark others for deletion
                for memory in toDelete {
                    processedIds.insert(memory.id)
                }
            }
        }
        
        // Add all non-processed memories (unchanged)
        for memory in allMemories {
            if !processedIds.contains(memory.id) {
                optimizedMemories.append(memory)
            }
        }
        
        // Save optimized memories back to database
        try await database.saveOptimizedMemories(optimizedMemories, options: options)
        
        // Perform maintenance if it's SQLite
        if database.databaseType == .sqlite {
            try await database.performMaintenance()
        }
        
        #if DEBUG
        print("Successfully optimized \\(clusters.count) clusters")
        print("Total memories before: \\(allMemories.count)")
        print("Total memories after: \\(optimizedMemories.count)")
        #endif
    }
    
    // MARK: - Cluster Preparation
    private func prepareClusterOptimization(
        _ cluster: MemoryCluster,
        options: OptimizationOptions
    ) async throws -> (merged: MemoryRecord, toDelete: [MemoryRecord]) {
        
        guard cluster.memories.count > 1 else {
            throw OptimizationError.invalidClusterSize(cluster.id)
        }
        
        // Keep the oldest memory as the primary
        let primary = cluster.memories.first!
        let secondaryMemories = Array(cluster.memories.dropFirst())
        
        // Prepare merged metadata
        var mergedMetadata = cluster.preservedMetadata
        
        if options.createAuditTrail {
            // Add audit information
            mergedMetadata["optimization_date"] = ISO8601DateFormatter().string(from: Date())
            mergedMetadata["merged_count"] = "\\(cluster.memories.count)"
            mergedMetadata["merged_ids"] = secondaryMemories.map { $0.id }.joined(separator: ",")
            mergedMetadata["original_content_hash"] = primary.contentHash
        }
        
        // Create optimized memory record
        let mergedMemory = MemoryRecord(
            id: primary.id,
            content: cluster.suggestedMerge,
            embedding: primary.embedding, // Preserve original embedding
            metadata: mergedMetadata,
            timestamp: primary.timestamp,
            contentHash: primary.contentHash
        )
        
        #if DEBUG
        print("Prepared cluster optimization:")
        print("  Primary ID: \\(primary.id)")
        print("  Merged content length: \\(cluster.suggestedMerge.count)")
        print("  Secondary IDs to delete: \\(secondaryMemories.map { $0.id })")
        #endif
        
        return (mergedMemory, secondaryMemories)
    }
    
    // MARK: - Validation
    func validateOptimization(
        clusters: [MemoryCluster],
        options: OptimizationOptions
    ) async throws {
        
        // Check if any clusters are approved
        guard !options.approvedClusters.isEmpty else {
            throw OptimizationError.noApprovedClusters
        }
        
        // Validate each approved cluster
        for cluster in clusters where options.approvedClusters.contains(cluster.id) {
            try await validateCluster(cluster)
        }
    }
    
    private func validateCluster(_ cluster: MemoryCluster) async throws {
        // Check for minimum cluster size
        guard cluster.memories.count >= 2 else {
            throw OptimizationError.invalidClusterSize(cluster.id)
        }
        
        // Check for empty suggested merge
        guard !cluster.suggestedMerge.isEmpty else {
            throw OptimizationError.emptySuggestedMerge(cluster.id)
        }
        
        // Check for potential data loss
        try validateNoDataLoss(in: cluster)
    }
    
    private func validateNoDataLoss(in cluster: MemoryCluster) throws {
        // Check if suggested merge contains key information from all memories
        let allContent = cluster.memories.map { $0.content }.joined(separator: " ")
        
        // Extract key terms (simple approach - could be enhanced)
        let keyTerms = extractKeyTerms(from: allContent)
        
        // Verify key terms are preserved in a more lenient way
        var missingTerms: [String] = []
        for term in keyTerms {
            if !cluster.suggestedMerge.lowercased().contains(term.lowercased()) {
                missingTerms.append(term)
            }
        }
        
        // Only throw if significant terms are missing
        if missingTerms.count > keyTerms.count / 3 {
            throw OptimizationError.potentialDataLoss(missingTerms.joined(separator: ", "))
        }
    }
    
    private func extractKeyTerms(from text: String) -> [String] {
        // Simple extraction of capitalized words and numbers
        let words = text.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        
        return words.filter { word in
            // Skip very short words
            guard word.count > 2 else { return false }
            
            // Keep capitalized words (proper nouns)
            if let first = word.first, first.isUppercase {
                return true
            }
            
            // Keep words with numbers
            if word.rangeOfCharacter(from: .decimalDigits) != nil {
                return true
            }
            
            return false
        }.prefix(20).map { String($0) } // Limit to top 20 terms
    }
    
    // MARK: - Preview Generation
    func generatePreview(
        for clusters: [MemoryCluster],
        approvedClusters: Set<UUID>
    ) async -> OptimizationPreview {
        
        let affectedClusters = clusters.filter { approvedClusters.contains($0.id) }
        
        let totalMemoriesBefore = affectedClusters.reduce(0) { $0 + $1.memories.count }
        let totalMemoriesAfter = affectedClusters.count
        
        let changes = affectedClusters.map { cluster in
            OptimizationChange(
                clusterId: cluster.id,
                memoriesBefore: cluster.memories.count,
                memoriesAfter: 1,
                oldContent: cluster.memories.map { $0.content },
                newContent: cluster.suggestedMerge
            )
        }
        
        return OptimizationPreview(
            totalMemoriesBefore: totalMemoriesBefore,
            totalMemoriesAfter: totalMemoriesAfter,
            spaceSavingsPercentage: calculateSpaceSavings(before: totalMemoriesBefore, after: totalMemoriesAfter),
            changes: changes
        )
    }
    
    private func calculateSpaceSavings(before: Int, after: Int) -> Int {
        guard before > 0 else { return 0 }
        return Int(((Double(before - after) / Double(before)) * 100))
    }
}

// MARK: - Supporting Types
enum OptimizationError: LocalizedError {
    case noApprovedClusters
    case invalidClusterSize(UUID)
    case emptySuggestedMerge(UUID)
    case potentialDataLoss(String)
    case databaseError(String)
    
    var errorDescription: String? {
        switch self {
        case .noApprovedClusters:
            return "No clusters have been approved for optimization"
        case .invalidClusterSize:
            return "Invalid cluster size for optimization"
        case .emptySuggestedMerge:
            return "Empty suggested merge for cluster"
        case .potentialDataLoss(let terms):
            return "Potential data loss detected: key terms not found in merged content: \(terms)"
        case .databaseError(let message):
            return "Database error during optimization: \(message)"
        }
    }
}

struct OptimizationPreview {
    let totalMemoriesBefore: Int
    let totalMemoriesAfter: Int
    let spaceSavingsPercentage: Int
    let changes: [OptimizationChange]
}

struct OptimizationChange: Identifiable {
    let id = UUID()
    let clusterId: UUID
    let memoriesBefore: Int
    let memoriesAfter: Int
    let oldContent: [String]
    let newContent: String
}
