//
//  AnalysisEngine.swift
//  Memory Defragmenter
//
//  Created by Nicholas Rogers on 11.06.2025.
//

import Foundation
import Accelerate

// MARK: - Analysis Engine
actor AnalysisEngine {
    private let similarityThreshold: Float = 0.85
    private let relatedThreshold: Float = 0.70
    
    // MARK: - Main Analysis
    func analyzeMemories(_ memories: [MemoryRecord]) async throws -> AnalysisResult {
        guard !memories.isEmpty else {
            return AnalysisResult(
                totalMemories: 0,
                duplicateClusters: [],
                potentialSavings: 0,
                recommendations: []
            )
        }
        
        // Start performance tracking
        let startTime = Date()
        
        // Find clusters
        let clusters = await findClusters(in: memories)
        
        // Calculate potential savings
        let totalDuplicates = clusters.reduce(0) { $0 + ($1.memories.count - 1) }
        let potentialSavings = memories.isEmpty ? 0 : Int((Double(totalDuplicates) / Double(memories.count)) * 100)
        
        // Generate recommendations
        let recommendations = generateRecommendations(for: clusters, totalMemories: memories.count)
        
        #if DEBUG
        let analysisTime = Date().timeIntervalSince(startTime)
        print("Analysis completed in \(String(format: "%.2f", analysisTime)) seconds")
        print("Found \(clusters.count) duplicate clusters")
        #endif
        
        return AnalysisResult(
            totalMemories: memories.count,
            duplicateClusters: clusters,
            potentialSavings: potentialSavings,
            recommendations: recommendations
        )
    }
    
    // MARK: - Clustering Algorithm
    private func findClusters(in memories: [MemoryRecord]) async -> [MemoryCluster] {
        var clusters: [MemoryCluster] = []
        var processed = Set<String>()
        
        // Process memories in batches for better performance
        let batchSize = 100
        
        for i in stride(from: 0, to: memories.count, by: batchSize) {
            let endIndex = min(i + batchSize, memories.count)
            let batch = Array(memories[i..<endIndex])
            
            await processBatch(batch, allMemories: memories, processed: &processed, clusters: &clusters)
            
            // Update progress
            let progress = Double(endIndex) / Double(memories.count)
            await updateProgress(progress)
        }
        
        return clusters.sorted { $0.memories.count > $1.memories.count }
    }
    
    private func processBatch(
        _ batch: [MemoryRecord],
        allMemories: [MemoryRecord],
        processed: inout Set<String>,
        clusters: inout [MemoryCluster]
    ) async {
        for memory in batch {
            if processed.contains(memory.id) { continue }
            
            // Find similar memories
            let similar = await findSimilarMemories(to: memory, in: allMemories, processed: processed)
            
            if similar.count > 1 {
                // Mark all as processed
                similar.forEach { processed.insert($0.id) }
                
                // Create cluster
                let cluster = await createCluster(from: similar)
                clusters.append(cluster)
            }
        }
    }
    
    private func findSimilarMemories(
        to target: MemoryRecord,
        in memories: [MemoryRecord],
        processed: Set<String>
    ) async -> [MemoryRecord] {
        var similar = [target]
        
        // Use concurrent processing for similarity calculations
        await withTaskGroup(of: (MemoryRecord, Float)?.self) { group in
            for memory in memories {
                if memory.id == target.id || processed.contains(memory.id) { continue }
                
                group.addTask {
                    let similarity = self.calculateSimilarity(target.embedding, memory.embedding)
                    
                    if similarity >= self.similarityThreshold {
                        return (memory, similarity)
                    }
                    return nil
                }
            }
            
            for await result in group {
                if let (memory, _) = result {
                    similar.append(memory)
                }
            }
        }
        
        return similar
    }
    
    // MARK: - Similarity Calculation
    nonisolated private func calculateSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        
        var dotProduct: Float = 0
        var magnitudeA: Float = 0
        var magnitudeB: Float = 0
        
        // Use Accelerate framework for optimized calculation
        vDSP_dotpr(a, 1, b, 1, &dotProduct, vDSP_Length(a.count))
        vDSP_svesq(a, 1, &magnitudeA, vDSP_Length(a.count))
        vDSP_svesq(b, 1, &magnitudeB, vDSP_Length(a.count))
        
        let denominator = sqrt(magnitudeA) * sqrt(magnitudeB)
        
        return denominator > 0 ? dotProduct / denominator : 0
    }
    
    // MARK: - Cluster Creation
    private func createCluster(from memories: [MemoryRecord]) async -> MemoryCluster {
        // Sort by timestamp to preserve the earliest
        let sorted = memories.sorted { $0.timestamp < $1.timestamp }
        
        // Calculate average similarity
        let avgSimilarity = await calculateAverageSimilarity(sorted)
        
        // Consolidate memories
        let consolidated = consolidateMemories(sorted)
        
        // Merge metadata
        let mergedMetadata = mergeMetadata(from: sorted)
        
        return MemoryCluster(
            memories: sorted,
            similarity: avgSimilarity,
            suggestedMerge: consolidated,
            preservedMetadata: mergedMetadata
        )
    }
    
    private func calculateAverageSimilarity(_ memories: [MemoryRecord]) async -> Float {
        guard memories.count > 1 else { return 1.0 }
        
        var totalSimilarity: Float = 0
        var comparisons = 0
        
        for i in 0..<memories.count {
            for j in (i+1)..<memories.count {
                let similarity = calculateSimilarity(memories[i].embedding, memories[j].embedding)
                totalSimilarity += similarity
                comparisons += 1
            }
        }
        
        return comparisons > 0 ? totalSimilarity / Float(comparisons) : 1.0
    }
    
    private func consolidateMemories(_ memories: [MemoryRecord]) -> String {
        guard !memories.isEmpty else { return "" }
        
        // Extract unique content
        let contents = memories.map { $0.content }
        let uniqueContent = extractUniqueInformation(from: contents)
        
        // Create consolidated memory with metadata
        let dateRange: String
        if memories.count > 1,
           let first = memories.first?.timestamp,
           let last = memories.last?.timestamp {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            dateRange = "\(formatter.string(from: first)) - \(formatter.string(from: last))"
        } else {
            dateRange = memories.first?.formattedDate ?? ""
        }
        
        return """
        \(uniqueContent)
        [Consolidated from \(memories.count) memories: \(dateRange)]
        """
    }
    
    private func extractUniqueInformation(from contents: [String]) -> String {
        guard !contents.isEmpty else { return "" }
        
        // For now, use the longest content as the base
        // TODO: Implement more sophisticated content merging
        let base = contents.max(by: { $0.count < $1.count }) ?? contents[0]
        
        // Find unique information in other contents
        var additionalInfo: [String] = []
        
        for content in contents where content != base {
            // Simple approach: find sentences not in base
            let sentences = content.components(separatedBy: ". ")
            for sentence in sentences {
                if !base.contains(sentence) && !sentence.isEmpty {
                    additionalInfo.append(sentence)
                }
            }
        }
        
        if additionalInfo.isEmpty {
            return base
        } else {
            return base + "\n\nAdditional information: " + additionalInfo.joined(separator: ". ")
        }
    }
    
    private func mergeMetadata(from memories: [MemoryRecord]) -> [String: String] {
        var merged: [String: String] = [:]
        
        // Collect all metadata
        for memory in memories {
            for (key, value) in memory.metadata {
                if let existing = merged[key] {
                    // If values differ, concatenate them
                    if existing != value {
                        merged[key] = "\(existing), \(value)"
                    }
                } else {
                    merged[key] = value
                }
            }
        }
        
        // Add consolidation metadata
        merged["consolidated_count"] = "\(memories.count)"
        merged["consolidated_date"] = ISO8601DateFormatter().string(from: Date())
        
        return merged
    }
    
    // MARK: - Recommendations
    private func generateRecommendations(for clusters: [MemoryCluster], totalMemories: Int) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // High duplicate count recommendation
        let duplicateCount = clusters.reduce(0) { $0 + ($1.memories.count - 1) }
        let duplicatePercentage = totalMemories > 0 ? (Double(duplicateCount) / Double(totalMemories)) * 100 : 0
        
        if duplicatePercentage > 30 {
            recommendations.append(Recommendation(
                type: .merge,
                title: "High Duplicate Count",
                description: "Over 30% of your memories are duplicates. Running optimization could significantly reduce database size.",
                impact: .high
            ))
        }
        
        // Large cluster recommendation
        if let largestCluster = clusters.max(by: { $0.memories.count < $1.memories.count }),
           largestCluster.memories.count > 10 {
            recommendations.append(Recommendation(
                type: .review,
                title: "Large Duplicate Cluster Found",
                description: "Found a cluster with \(largestCluster.memories.count) similar memories. Review this cluster carefully before merging.",
                impact: .medium
            ))
        }
        
        // Archive recommendation
        let oldMemories = clusters.flatMap { $0.memories }.filter { memory in
            let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
            return memory.timestamp < sixMonthsAgo
        }
        
        if oldMemories.count > 50 {
            recommendations.append(Recommendation(
                type: .archive,
                title: "Archive Old Duplicates",
                description: "Found \(oldMemories.count) duplicate memories older than 6 months. Consider archiving instead of merging.",
                impact: .low
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Progress Tracking
    private func updateProgress(_ progress: Double) async {
        // Update progress for UI
        // This would typically post to a publisher or update a shared state
        #if DEBUG
        if Int(progress * 100) % 10 == 0 {
            print("Analysis progress: \(Int(progress * 100))%")
        }
        #endif
    }
}
