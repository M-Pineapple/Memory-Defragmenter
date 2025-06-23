//
//  ContentView.swift
//  Memory Defragmenter
//
//  Created by Nicholas Rogers on 11.06.2025.
//

import SwiftUI
import Charts

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            SidebarView()
                .navigationSplitViewColumnWidth(min: 250, ideal: 300)
        } content: {
            // Main content area
            if viewModel.isAnalyzing {
                AnalysisInProgressView()
            } else if let results = viewModel.analysisResults {
                ResultsView(results: results)
            } else if viewModel.isDatabaseOpen {
                DatabaseLoadedView()
            } else {
                WelcomeView()
            }
        } detail: {
            // Detail view for selected cluster
            if let selectedCluster = viewModel.selectedCluster {
                ClusterDetailView(cluster: selectedCluster)
            } else {
                Text("Select a cluster to view details")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.currentError != nil)) {
            Button("OK") {
                viewModel.currentError = nil
            }
        } message: {
            if let error = viewModel.currentError {
                Text(error.localizedDescription)
            }
        }
        .sheet(isPresented: $viewModel.showingStatistics) {
            if let results = viewModel.analysisResults {
                StatisticsView(results: results)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if viewModel.analysisResults != nil {
                    Menu {
                        Button("Export as JSON") {
                            if let results = viewModel.analysisResults {
                                viewModel.isExporting = true
                                ExportManager.exportAnalysisResults(results, format: .json)
                                viewModel.isExporting = false
                            }
                        }
                        .disabled(viewModel.isExporting)
                        
                        Button("Export as CSV") {
                            if let results = viewModel.analysisResults {
                                viewModel.isExporting = true
                                ExportManager.exportAnalysisResults(results, format: .csv)
                                viewModel.isExporting = false
                            }
                        }
                        .disabled(viewModel.isExporting)
                        
                        Button("Export as Markdown") {
                            if let results = viewModel.analysisResults {
                                viewModel.isExporting = true
                                ExportManager.exportAnalysisResults(results, format: .markdown)
                                viewModel.isExporting = false
                            }
                        }
                        .disabled(viewModel.isExporting)
                        
                        Button("Export as HTML") {
                            if let results = viewModel.analysisResults {
                                viewModel.isExporting = true
                                ExportManager.exportAnalysisResults(results, format: .html)
                                viewModel.isExporting = false
                            }
                        }
                        .disabled(viewModel.isExporting)
                    } label: {
                        if viewModel.isExporting {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                    }
                    .disabled(viewModel.isExporting)
                    
                    Button {
                        viewModel.showingStatistics = true
                    } label: {
                        Label("Statistics", systemImage: "chart.bar")
                    }
                    

                }
            }
        }
    }
}

// MARK: - Sidebar View
struct SidebarView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        List {
            Section("Database") {
                if let path = viewModel.databasePath {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "cylinder.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("Current Database")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(URL(fileURLWithPath: path).lastPathComponent)
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        
                        // File management options
                        HStack(spacing: 12) {
                            Button(action: {
                                viewModel.closeDatabase()
                            }) {
                                Label("Close", systemImage: "xmark.circle")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                viewModel.openDatabase()
                            }) {
                                Label("Change", systemImage: "arrow.triangle.2.circlepath")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    Button(action: {
                        viewModel.openDatabase()
                    }) {
                        Label("Open Database", systemImage: "folder.badge.plus")
                    }
                }
            }
            
            if let results = viewModel.analysisResults {
                Section("Analysis Results") {
                    StatisticRow(
                        icon: "doc.text.fill",
                        title: "Total Memories",
                        value: "\(results.totalMemories)"
                    )
                    
                    StatisticRow(
                        icon: "doc.on.doc.fill",
                        title: "Duplicate Clusters",
                        value: "\(results.duplicateClusters.count)"
                    )
                    
                    StatisticRow(
                        icon: "arrow.down.circle.fill",
                        title: "Potential Savings",
                        value: "\(results.potentialSavings)%"
                    )
                }
                
                Section("Actions") {
                    Button(action: {
                        Task {
                            await viewModel.refreshAnalysis()
                        }
                    }) {
                        Label("Refresh Analysis", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isAnalyzing)
                    
                    Button(action: {
                        Task {
                            await viewModel.performOptimization()
                        }
                    }) {
                        Label("Optimize Database", systemImage: "sparkles")
                    }
                    .disabled(!viewModel.hasApprovedChanges)
                }
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Memory Defragmenter")
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            // Logo matching the app icon
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.357, green: 0.62, blue: 1.0), 
                                Color(red: 0.627, green: 0.471, blue: 0.918)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 150, height: 150)
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                
                // Memory chip icon
                ZStack {
                    // Main chip body
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .frame(width: 80, height: 60)
                    
                    // Top pins
                    HStack(spacing: 8) {
                        ForEach(0..<4) { _ in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 8, height: 15)
                        }
                    }
                    .offset(y: -37)
                    
                    // Bottom pins
                    HStack(spacing: 8) {
                        ForEach(0..<4) { _ in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 8, height: 15)
                        }
                    }
                    .offset(y: 37)
                    
                    // Side pins
                    VStack(spacing: 8) {
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 15, height: 8)
                        }
                    }
                    .offset(x: -47)
                    
                    VStack(spacing: 8) {
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 15, height: 8)
                        }
                    }
                    .offset(x: 47)
                }
            }
            
            Text("Memory Defragmenter")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Optimize your Memory MCP database by consolidating\nduplicates and organizing memories")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)
            
            Button(action: {
                viewModel.openDatabase()
            }) {
                Label("Open Database", systemImage: "folder.badge.plus")
                    .font(.title3)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Database Loaded View
struct DatabaseLoadedView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.green)
            
            Text("Database Loaded")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let path = viewModel.databasePath {
                VStack(spacing: 12) {
                    Text(URL(fileURLWithPath: path).lastPathComponent)
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    // Add file management buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            viewModel.closeDatabase()
                        }) {
                            Label("Close", systemImage: "xmark.circle")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            viewModel.openDatabase()
                        }) {
                            Label("Open Different Database", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.caption)
                }
            }
            
            Button(action: {
                Task {
                    await viewModel.startAnalysis()
                }
            }) {
                Label("Start Analysis", systemImage: "magnifyingglass")
                    .font(.title3)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Analysis In Progress View
struct AnalysisInProgressView: View {
    @State private var animationProgress = 0.0
    
    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(2)
            
            Text("Analyzing Memories...")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Finding duplicate clusters and calculating similarities")
                .font(.title3)
                .foregroundColor(.secondary)
            
            // Animated progress indicator
            HStack(spacing: 12) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                        .scaleEffect(animationProgress == Double(index) ? 1.5 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(), value: animationProgress)
                }
            }
            .onAppear {
                withAnimation {
                    animationProgress = 2.0
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Results View
struct ResultsView: View {
    let results: AnalysisResult
    @EnvironmentObject var viewModel: AppViewModel
    @State private var searchText = ""
    @State private var sortOrder = [KeyPathComparator(\MemoryCluster.memories.count, order: .reverse)]
    
    var filteredClusters: [MemoryCluster] {
        if searchText.isEmpty {
            return results.duplicateClusters
        } else {
            return results.duplicateClusters.filter { cluster in
                cluster.suggestedMerge.localizedCaseInsensitiveContains(searchText) ||
                cluster.memories.contains { $0.content.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Summary Section
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    SummaryCard(
                        title: "Total Memories",
                        value: "\(results.totalMemories)",
                        icon: "doc.text.fill",
                        color: .blue
                    )
                    
                    SummaryCard(
                        title: "Duplicates Found",
                        value: "\(results.totalDuplicates)",
                        icon: "doc.on.doc.fill",
                        color: .orange
                    )
                    
                    SummaryCard(
                        title: "Space Savings",
                        value: "\(results.potentialSavings)%",
                        icon: "arrow.down.circle.fill",
                        color: .green
                    )
                    
                    SummaryCard(
                        title: "Clusters",
                        value: "\(results.duplicateClusters.count)",
                        icon: "square.grid.3x3.fill",
                        color: .purple
                    )
                }
                .padding()
            }
            
            Divider()
            
            // Cluster Size Distribution Chart
            if !results.duplicateClusters.isEmpty {
                VStack(alignment: .leading) {
                    Text("Cluster Size Distribution")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Chart(results.clusterSizes, id: \.id) { cluster in
                        BarMark(
                            x: .value("Cluster", cluster.id),
                            y: .value("Size", cluster.size)
                        )
                        .foregroundStyle(by: .value("Type", cluster.type))
                    }
                    .frame(height: 150)
                    .padding()
                }
                
                Divider()
            }
            
            // Clusters Table
            Table(filteredClusters, sortOrder: $sortOrder) {
                TableColumn("") { cluster in
                    Toggle("", isOn: viewModel.binding(for: cluster))
                        .toggleStyle(.checkbox)
                }
                .width(40)
                
                TableColumn("Size", value: \.memories.count) { cluster in
                    HStack {
                        Text("\(cluster.memories.count)")
                            .fontWeight(.medium)
                        Text("memories")
                            .foregroundColor(.secondary)
                    }
                }
                .width(100)
                
                TableColumn("Similarity", value: \.similarity) { cluster in
                    HStack {
                        ProgressView(value: Double(cluster.similarity))
                            .progressViewStyle(.linear)
                            .frame(width: 80)
                        Text("\(Int(cluster.similarity * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .width(140)
                
                TableColumn("Date Range") { cluster in
                    if let oldest = cluster.oldestMemory,
                       let newest = cluster.newestMemory {
                        Text("\(oldest.formattedDate) - \(newest.formattedDate)")
                            .font(.caption)
                    }
                }
                
                TableColumn("Preview") { cluster in
                    Text(cluster.suggestedMerge)
                        .lineLimit(2)
                        .truncationMode(.tail)
                }
                
                TableColumn("Actions") { cluster in
                    HStack {
                        Button {
                            viewModel.selectedCluster = cluster
                        } label: {
                            Image(systemName: "eye")
                        }
                        .buttonStyle(.borderless)
                        .help("View Details")
                        
                        Button {
                            viewModel.inspectCluster(cluster)
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        .buttonStyle(.borderless)
                        .help("Inspect Cluster")
                    }
                }
                .width(80)
            }
            .searchable(text: $searchText, prompt: "Search memories...")
            
            // Bottom Toolbar
            HStack {
                Text("\(viewModel.approvedClusters.count) of \(results.duplicateClusters.count) clusters selected")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Select All") {
                    for cluster in results.duplicateClusters {
                        viewModel.approvedClusters.insert(cluster.id)
                    }
                }
                .disabled(viewModel.approvedClusters.count == results.duplicateClusters.count)
                
                Button("Clear Selection") {
                    viewModel.approvedClusters.removeAll()
                }
                .disabled(viewModel.approvedClusters.isEmpty)
                
                Divider()
                    .frame(height: 20)
                
                Button("Preview Changes") {
                    viewModel.showPreview()
                }
                .disabled(viewModel.approvedClusters.isEmpty)
                
                Button("Optimize") {
                    Task {
                        await viewModel.performOptimization()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.hasApprovedChanges)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
    }
}

// MARK: - Supporting Views
struct StatisticRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
            }
            Spacer()
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 150)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Cluster Detail View
struct ClusterDetailView: View {
    let cluster: MemoryCluster
    @State private var selectedMemoryIndex = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Cluster Details")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("\(cluster.memories.count) similar memories • \(Int(cluster.similarity * 100))% similarity")
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Suggested Merge
                    GroupBox("Consolidated Memory") {
                        Text(cluster.suggestedMerge)
                            .textSelection(.enabled)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Original Memories
                    GroupBox("Original Memories") {
                        ForEach(Array(cluster.memories.enumerated()), id: \.element.id) { index, memory in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Memory \(index + 1)")
                                        .font(.headline)
                                    Spacer()
                                    Text(memory.formattedDate)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(memory.content)
                                    .textSelection(.enabled)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.blue.opacity(0.05))
                                    .cornerRadius(8)
                                
                                if !memory.metadata.isEmpty {
                                    DisclosureGroup("Metadata") {
                                        ForEach(Array(memory.metadata.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                                            HStack {
                                                Text(key)
                                                    .fontWeight(.medium)
                                                Spacer()
                                                Text(value)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.vertical, 2)
                                        }
                                    }
                                    .font(.caption)
                                }
                            }
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 400)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
        .frame(width: 1200, height: 800)
}
