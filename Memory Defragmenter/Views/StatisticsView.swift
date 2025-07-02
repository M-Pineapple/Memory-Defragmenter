//
//  StatisticsView.swift
//  Memory Defragmenter
//
//  Created by Pineapple 🍍 on 11.06.2025.
//

import SwiftUI
import Charts

struct StatisticsView: View {
    let results: AnalysisResult
    @State private var selectedTimeRange = TimeRange.all
    @Environment(\.dismiss) private var dismiss
    
    enum TimeRange: String, CaseIterable {
        case all = "All Time"
        case year = "Past Year"
        case sixMonths = "6 Months"
        case month = "Past Month"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Database Statistics")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Summary Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "Total Memories",
                            value: "\(results.totalMemories)",
                            icon: "doc.text.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Unique Memories",
                            value: "\(results.totalMemories - results.totalDuplicates)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Duplicates",
                            value: "\(results.totalDuplicates)",
                            icon: "doc.on.doc.fill",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Clusters",
                            value: "\(results.duplicateClusters.count)",
                            icon: "square.grid.3x3.fill",
                            color: .purple
                        )
                    }
                    
                    // Similarity Distribution Chart
                    GroupBox("Similarity Distribution") {
                        if !results.duplicateClusters.isEmpty {
                            Chart(results.duplicateClusters) { cluster in
                                BarMark(
                                    x: .value("Similarity", Int(cluster.similarity * 100)),
                                    y: .value("Count", 1)
                                )
                                .foregroundStyle(.blue.gradient)
                            }
                            .frame(height: 200)
                            .chartXAxis {
                                AxisMarks(values: [70, 80, 90, 100]) { value in
                                    AxisValueLabel {
                                        Text("\(value.as(Int.self) ?? 0)%")
                                    }
                                }
                            }
                            .chartXScale(domain: 70...100)
                        } else {
                            Text("No duplicate clusters found")
                                .foregroundColor(.secondary)
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // Memory Timeline
                    GroupBox("Memory Timeline") {
                        if let oldestMemory = results.duplicateClusters.compactMap({ $0.oldestMemory }).min(by: { $0.timestamp < $1.timestamp }),
                           let newestMemory = results.duplicateClusters.compactMap({ $0.newestMemory }).max(by: { $0.timestamp < $1.timestamp }) {
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Label("Oldest Memory", systemImage: "clock.badge.xmark")
                                    Spacer()
                                    Text(oldestMemory.formattedDate)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Label("Newest Memory", systemImage: "clock.badge.checkmark")
                                    Spacer()
                                    Text(newestMemory.formattedDate)
                                        .foregroundColor(.secondary)
                                }
                                
                                let daysBetween = Calendar.current.dateComponents([.day], from: oldestMemory.timestamp, to: newestMemory.timestamp).day ?? 0
                                
                                HStack {
                                    Label("Time Span", systemImage: "calendar")
                                    Spacer()
                                    Text("\(daysBetween) days")
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Text("No timeline data available")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // Recommendations
                    if !results.recommendations.isEmpty {
                        GroupBox("Recommendations") {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(results.recommendations) { recommendation in
                                    HStack(alignment: .top) {
                                        Image(systemName: iconForRecommendation(recommendation.type))
                                            .foregroundColor(colorForImpact(recommendation.impact))
                                            .frame(width: 24)
                                        
                                        VStack(alignment: .leading) {
                                            Text(recommendation.title)
                                                .fontWeight(.medium)
                                            Text(recommendation.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    if recommendation.id != results.recommendations.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 800, height: 600)
    }
    
    func iconForRecommendation(_ type: RecommendationType) -> String {
        switch type {
        case .merge: return "doc.on.doc"
        case .archive: return "archivebox"
        case .reorganize: return "folder.badge.gearshape"
        case .review: return "magnifyingglass"
        }
    }
    
    func colorForImpact(_ impact: Impact) -> Color {
        switch impact {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
