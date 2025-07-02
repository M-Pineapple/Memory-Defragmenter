//
//  AppViewModel.swift
//  Memory Defragmenter
//
//  Created by Pineapple 🍍 on 11.06.2025.
//

import SwiftUI
import Combine
import AppKit
import UniformTypeIdentifiers

// Using the new @Observable macro from Swift 6
@Observable
final class AppViewModel: ObservableObject {
    // MARK: - Published Properties
    var isAnalyzing = false
    var isExporting = false
    var analysisResults: AnalysisResult?
    var selectedCluster: MemoryCluster?
    var approvedClusters = Set<UUID>()
    var currentError: Error?
    var showingInspector = false
    var showAboutWindow = false
    var showingStatistics = false
    var databasePath: String?
    
    // MARK: - Progress Tracking (Xcode 26 feature)
    var optimizationProgress: Progress?
    
    // MARK: - Private Properties
    private var analysisEngine: AnalysisEngine?
    private var database: UnifiedMemoryDatabase?
    
    // MARK: - Computed Properties
    var hasApprovedChanges: Bool {
        !approvedClusters.isEmpty
    }
    
    var isDatabaseOpen: Bool {
        database != nil
    }
    
    // MARK: - Public Methods
    func closeDatabase() {
        database = nil
        databasePath = nil
        analysisResults = nil
        selectedCluster = nil
        approvedClusters.removeAll()
        currentError = nil
    }
    
    func openDatabase() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        // Allow various database file types
        openPanel.allowedContentTypes = [
            UTType(filenameExtension: "db")!,
            UTType(filenameExtension: "sqlite")!,
            UTType(filenameExtension: "sqlite3")!,
            UTType.database,
            UTType.data
        ]
        openPanel.allowsOtherFileTypes = true
        openPanel.message = "Select the ChromaDB folder (not a file inside it)"
        openPanel.prompt = "Select Folder"
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                Task {
                    await self.loadDatabase(at: url.path)
                }
            }
        }
    }
    
    @MainActor
    func loadDatabase(at path: String) async {
        do {
            // If it's a test database or read-only, copy to Documents folder
            let fileManager = FileManager.default
            var finalPath = path
            
            if !fileManager.isWritableFile(atPath: path) || path.contains("test_memory") {
                // Copy to Documents folder
                let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileName = URL(fileURLWithPath: path).lastPathComponent
                let destinationPath = documentsPath.appendingPathComponent("MemoryDefragmenter_\(fileName)")
                
                // Remove existing copy if it exists
                try? fileManager.removeItem(at: destinationPath)
                
                // Copy the database
                try fileManager.copyItem(at: URL(fileURLWithPath: path), to: destinationPath)
                finalPath = destinationPath.path
                
                print("Copied database to writable location: \(finalPath)")
            }
            
            databasePath = finalPath
            database = UnifiedMemoryDatabase(path: finalPath)
            try await database?.connect()
            
            // Reset any previous analysis
            analysisResults = nil
            selectedCluster = nil
            approvedClusters.removeAll()
            
        } catch {
            currentError = error
            print("Failed to load database: \\(error)")
        }
    }
    
    @MainActor
    func startAnalysis() async {
        guard let db = database else { return }
        
        print("[Analysis] Starting analysis...")
        isAnalyzing = true
        currentError = nil
        
        do {
            // Create analysis engine if needed
            if analysisEngine == nil {
                analysisEngine = AnalysisEngine()
            }
            
            // Load memories from database
            print("[Analysis] Loading memories from database...")
            let memories = try await db.loadAllMemories()
            print("[Analysis] Loaded \(memories.count) memories")
            
            // Perform analysis
            print("[Analysis] Starting duplicate analysis...")
            let results = try await analysisEngine!.analyzeMemories(memories)
            print("[Analysis] Found \(results.duplicateClusters.count) duplicate clusters")
            
            self.analysisResults = results
            
        } catch {
            currentError = error
            print("Analysis failed: \\(error)")
        }
        
        isAnalyzing = false
    }
    
    func inspectCluster(_ cluster: MemoryCluster) {
        selectedCluster = cluster
        showingInspector = true
    }
    
    func showPreview() {
        // TODO: Implement preview functionality
    }
    
    @MainActor
    func performOptimization() async {
        guard let db = database,
              let results = analysisResults,
              !approvedClusters.isEmpty else { return }
        
        do {
            // For ChromaDB, handle backup differently
            if db.databaseType == .chromaDB {
                // ChromaDB adapter handles its own backups
                print("[Optimization] Starting ChromaDB optimization...")
            } else {
                // Create backup for SQLite databases
                let backupManager = try BackupManager()
                let backup = try await backupManager.createBackup(of: URL(fileURLWithPath: databasePath!))
                print("Created backup: \(backup.id)")
            }
            
            // Filter approved clusters
            let clustersToOptimize = results.duplicateClusters.filter { 
                approvedClusters.contains($0.id) 
            }
            
            // Create optimization options
            let options = OptimizationOptions(
                approvedClusters: approvedClusters,
                preserveMetadata: true,
                createAuditTrail: true
            )
            
            // Perform optimization using unified database
            let optimizer = OptimizationEngine()
            try await optimizer.optimizeDatabase(db, clusters: clustersToOptimize, options: options)
            
            // Refresh analysis
            await startAnalysis()
            
        } catch {
            currentError = error
            print("Optimization failed: \\(error)")
        }
    }
    
    @MainActor
    func refreshAnalysis() async {
        await startAnalysis()
    }
    
    // MARK: - Helper Methods
    func binding(for cluster: MemoryCluster) -> Binding<Bool> {
        Binding(
            get: { self.approvedClusters.contains(cluster.id) },
            set: { isOn in
                if isOn {
                    self.approvedClusters.insert(cluster.id)
                } else {
                    self.approvedClusters.remove(cluster.id)
                }
            }
        )
    }
}

// MARK: - Error Types
enum AppError: LocalizedError {
    case databaseNotFound
    case analysisInProgress
    case noApprovedClusters
    
    var errorDescription: String? {
        switch self {
        case .databaseNotFound:
            return "No database is currently open"
        case .analysisInProgress:
            return "Analysis is already in progress"
        case .noApprovedClusters:
            return "No clusters have been approved for optimization"
        }
    }
}
