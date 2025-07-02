//
//  ExportManager.swift
//  Memory Defragmenter
//
//  Created by Pineapple 🍍 on 11.06.2025.
//

import Foundation
import AppKit
import UniformTypeIdentifiers

enum ExportFormat {
    case json
    case csv
    case markdown
    case html
    
    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        case .markdown: return "md"
        case .html: return "html"
        }
    }
    
    var contentType: UTType {
        switch self {
        case .json: return .json
        case .csv: return .commaSeparatedText
        case .markdown: return .plainText
        case .html: return .html
        }
    }
}

class ExportManager {
    
    // Test method - write to app's Documents folder
    @MainActor
    static func testSimpleExport() {
        print("\n=== SIMPLE EXPORT TEST ===")
        print("Creating minimal test content...")
        
        let testContent = """
        Test Export from Memory Defragmenter
        Date: \(Date())
        
        This is a test export to verify the export functionality works.
        If you can see this file, the basic export mechanism is functioning.
        """
        
        // Use app's Documents directory instead of Desktop
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let appDocsURL = documentsURL.appendingPathComponent("MemoryDefragmenter", isDirectory: true)
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: appDocsURL, withIntermediateDirectories: true)
        
        let testFileURL = appDocsURL.appendingPathComponent("SimpleTest.txt")
        
        print("Attempting to write to: \(testFileURL.path)")
        
        do {
            try testContent.write(to: testFileURL, atomically: true, encoding: .utf8)
            print("✅ SUCCESS: File written to \(testFileURL.path)")
            
            // Show in Finder
            NSWorkspace.shared.activateFileViewerSelecting([testFileURL])
            
            let alert = NSAlert()
            alert.messageText = "Test Export Successful"
            alert.informativeText = "Test file saved to: \(testFileURL.path)"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            
        } catch {
            print("❌ FAILED: \(error)")
            
            let alert = NSAlert()
            alert.messageText = "Test Export Failed"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        
        print("=== END SIMPLE EXPORT TEST ===\n")
    }
    
    @MainActor
    static func exportAnalysisResults(_ results: AnalysisResult, format: ExportFormat) {
        print("Export requested for format: \(format.fileExtension)")
        print("Number of clusters to export: \(results.duplicateClusters.count)")
        print("Total memories in clusters: \(results.duplicateClusters.reduce(0) { $0 + $1.memories.count })")
        
        // Create save panel - this gives us proper permissions
        let savePanel = NSSavePanel()
        savePanel.title = "Export Analysis Results"
        savePanel.message = "Choose where to save the analysis results"
        savePanel.nameFieldStringValue = "MemoryAnalysis_\(Date.now.formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).\(format.fileExtension)"
        savePanel.allowedContentTypes = [format.contentType]
        savePanel.canCreateDirectories = true
        
        // Run the save panel
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                print("User selected: \(url.path)")
                
                // Generate content
                DispatchQueue.main.async {
                    let startTime = Date()
                    let content = generateContent(for: results, format: format)
                    let generationTime = Date().timeIntervalSince(startTime)
                    print("Content generated in \(generationTime) seconds, size: \(content.count) characters")
                    
                    // Write file
                    do {
                        try content.write(to: url, atomically: true, encoding: .utf8)
                        print("✅ Export successful: \(url.lastPathComponent)")
                        
                        // Show success
                        let alert = NSAlert()
                        alert.messageText = "Export Successful"
                        alert.informativeText = "Exported to: \(url.lastPathComponent)"
                        alert.alertStyle = .informational
                        alert.addButton(withTitle: "Show in Finder")
                        alert.addButton(withTitle: "OK")
                        
                        if alert.runModal() == .alertFirstButtonReturn {
                            NSWorkspace.shared.activateFileViewerSelecting([url])
                        }
                        
                    } catch {
                        print("❌ Export failed: \(error)")
                        showNotification(title: "Export Failed", 
                                       message: error.localizedDescription,
                                       isError: true)
                    }
                }
            } else {
                print("Export cancelled")
            }
        }
    }
    
    @MainActor
    static func exportOptimizationReport(_ results: AnalysisResult, optimizedClusters: [MemoryCluster]) {
        let savePanel = NSSavePanel()
        
        // Configure save panel
        savePanel.title = "Export Optimization Report"
        savePanel.message = "Choose where to save the optimization report"
        savePanel.prompt = "Export"
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "OptimizationReport_\(Date.now.formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).pdf"
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        
        // Set default directory
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            savePanel.directoryURL = documentsURL
        }
        
        let response = savePanel.runModal()
        
        if response == .OK, let url = savePanel.url {
            Task {
                do {
                    let pdfData = generatePDFReport(results: results, optimizedClusters: optimizedClusters)
                    try pdfData.write(to: url)
                    
                    showNotification(title: "Report Exported", 
                                         message: "Optimization report saved successfully",
                                         isError: false)
                    
                    // Open the PDF
                    NSWorkspace.shared.open(url)
                    
                } catch {
                    print("PDF export failed: \(error)")
                    showNotification(title: "Export Failed", 
                                         message: error.localizedDescription,
                                         isError: true)
                }
            }
        }
    }
    
    private static func generateContent(for results: AnalysisResult, format: ExportFormat) -> String {
        switch format {
        case .json:
            return generateJSON(results)
        case .csv:
            return generateCSV(results)
        case .markdown:
            return generateMarkdown(results)
        case .html:
            return generateHTML(results)
        }
    }
    
    private static func generateJSON(_ results: AnalysisResult) -> String {
        let dateFormatter = ISO8601DateFormatter()
        
        print("Starting JSON generation...")
        
        // Limit memories per cluster to prevent huge exports
        let maxMemoriesPerCluster = 100
        
        let exportData: [String: Any] = [
            "analysisReport": [
                "timestamp": dateFormatter.string(from: results.timestamp),
                "totalMemories": results.totalMemories,
                "duplicateClusters": results.duplicateClusters.count,
                "totalDuplicates": results.totalDuplicates,
                "potentialSavingsPercentage": results.potentialSavings,
                "clusters": results.duplicateClusters.map { cluster in
                    print("Processing cluster with \(cluster.memories.count) memories")
                    let memoriesToInclude = Array(cluster.memories.prefix(maxMemoriesPerCluster))
                    let truncated = cluster.memories.count > maxMemoriesPerCluster
                    
                    return [
                        "id": cluster.id.uuidString,
                        "size": cluster.memories.count,
                        "similarity": cluster.similarity,
                        "dateRange": [
                            "oldest": cluster.oldestMemory?.timestamp.formatted() ?? "Unknown",
                            "newest": cluster.newestMemory?.timestamp.formatted() ?? "Unknown"
                        ],
                        "suggestedMerge": cluster.suggestedMerge,
                        "memoriesIncluded": memoriesToInclude.count,
                        "memoriesTruncated": truncated,
                        "memories": memoriesToInclude.map { memory in
                            [
                                "id": memory.id,
                                "content": String(memory.content.prefix(1000)), // Limit content length
                                "timestamp": dateFormatter.string(from: memory.timestamp),
                                "metadata": memory.metadata
                            ]
                        }
                    ] as [String : Any]
                },
                "recommendations": results.recommendations.map { rec in
                    [
                        "title": rec.title,
                        "description": rec.description,
                        "type": "\(rec.type)",
                        "impact": "\(rec.impact)"
                    ]
                }
            ]
        ]
        
        print("Converting to JSON...")
        
        do {
            let data = try JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
            let jsonString = String(data: data, encoding: .utf8) ?? "{}"
            print("JSON generation complete")
            return jsonString
        } catch {
            print("JSON serialization error: \(error)")
            return "{}"
        }
    }
    
    private static func generateCSV(_ results: AnalysisResult) -> String {
        print("Starting CSV generation...")
        var csv = "Cluster ID,Size,Similarity %,Oldest Date,Newest Date,Suggested Merge\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        for (index, cluster) in results.duplicateClusters.enumerated() {
            print("Processing CSV cluster \(index + 1) of \(results.duplicateClusters.count)")
            
            let oldestDate = cluster.oldestMemory?.timestamp ?? Date()
            let newestDate = cluster.newestMemory?.timestamp ?? Date()
            
            // Escape quotes in the suggested merge text
            let escapedMerge = cluster.suggestedMerge
                .replacingOccurrences(of: "\"", with: "\"\"")
                .replacingOccurrences(of: "\n", with: " ")
            
            csv += "\(index + 1),"
            csv += "\(cluster.memories.count),"
            csv += "\(Int(cluster.similarity * 100)),"
            csv += "\"\(dateFormatter.string(from: oldestDate))\","
            csv += "\"\(dateFormatter.string(from: newestDate))\","
            csv += "\"\(escapedMerge)\"\n"
        }
        
        // Add summary section
        csv += "\n\nSummary\n"
        csv += "Total Memories,\(results.totalMemories)\n"
        csv += "Duplicate Clusters,\(results.duplicateClusters.count)\n"
        csv += "Total Duplicates,\(results.totalDuplicates)\n"
        csv += "Potential Savings %,\(results.potentialSavings)\n"
        
        print("CSV generation complete")
        return csv
    }
    
    private static func generateMarkdown(_ results: AnalysisResult) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        var markdown = """
        # Memory Defragmenter Analysis Report
        
        **Generated**: \(dateFormatter.string(from: Date()))
        
        ## Summary
        
        | Metric | Value |
        |--------|-------|
        | Total Memories | \(results.totalMemories) |
        | Duplicate Clusters | \(results.duplicateClusters.count) |
        | Total Duplicates | \(results.totalDuplicates) |
        | Potential Savings | \(results.potentialSavings)% |
        
        ## Duplicate Clusters
        
        """
        
        for (index, cluster) in results.duplicateClusters.enumerated() {
            let oldestDate = cluster.oldestMemory?.timestamp ?? Date()
            let newestDate = cluster.newestMemory?.timestamp ?? Date()
            
            markdown += """
            
            ### Cluster \(index + 1)
            
            - **Size**: \(cluster.memories.count) memories
            - **Similarity**: \(Int(cluster.similarity * 100))%
            - **Date Range**: \(dateFormatter.string(from: oldestDate)) to \(dateFormatter.string(from: newestDate))
            
            #### Suggested Merge:
            ```
            \(cluster.suggestedMerge)
            ```
            
            """
            
            if cluster.memories.count <= 5 {
                markdown += "#### Original Memories:\n"
                for (i, memory) in cluster.memories.enumerated() {
                    markdown += "\n\(i + 1). \(memory.content.prefix(100))...\n"
                }
            }
        }
        
        if !results.recommendations.isEmpty {
            markdown += "\n## Recommendations\n\n"
            for recommendation in results.recommendations {
                markdown += "### \(recommendation.title)\n\(recommendation.description)\n\n"
            }
        }
        
        return markdown
    }
    
    private static func generateHTML(_ results: AnalysisResult) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Memory Defragmenter Analysis Report</title>
            <style>
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                    max-width: 900px; 
                    margin: 0 auto; 
                    padding: 20px;
                    line-height: 1.6;
                    color: #333;
                }
                h1, h2, h3 { color: #2c3e50; }
                h1 { border-bottom: 3px solid #3498db; padding-bottom: 10px; }
                .summary { 
                    background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
                    padding: 25px; 
                    border-radius: 10px; 
                    margin: 20px 0;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                }
                .cluster { 
                    border: 1px solid #e0e0e0; 
                    padding: 20px; 
                    margin: 15px 0; 
                    border-radius: 8px;
                    background: #ffffff;
                    box-shadow: 0 1px 3px rgba(0,0,0,0.05);
                }
                .cluster:hover {
                    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
                    transition: box-shadow 0.3s ease;
                }
                .stat { 
                    display: inline-block; 
                    margin: 15px 20px 15px 0;
                    text-align: center;
                }
                .stat-value { 
                    font-size: 36px; 
                    font-weight: bold; 
                    color: #3498db;
                    display: block;
                }
                .stat-label {
                    font-size: 14px;
                    color: #7f8c8d;
                    text-transform: uppercase;
                    letter-spacing: 1px;
                }
                .recommendation { 
                    background: #fff3cd; 
                    border-left: 4px solid #ffc107;
                    padding: 15px; 
                    margin: 10px 0; 
                    border-radius: 4px; 
                }
                blockquote {
                    background: #f9f9f9;
                    border-left: 4px solid #3498db;
                    margin: 15px 0;
                    padding: 15px 20px;
                    font-style: italic;
                }
                .metadata {
                    font-size: 14px;
                    color: #7f8c8d;
                }
                .date-range {
                    background: #ecf0f1;
                    padding: 5px 10px;
                    border-radius: 15px;
                    display: inline-block;
                    font-size: 13px;
                }
            </style>
        </head>
        <body>
            <h1>🧠 Memory Defragmenter Analysis Report</h1>
            <p class="metadata"><strong>Generated:</strong> \(dateFormatter.string(from: Date()))</p>
            
            <div class="summary">
                <h2>📊 Summary</h2>
                <div class="stat">
                    <span class="stat-value">\(results.totalMemories)</span>
                    <span class="stat-label">Total Memories</span>
                </div>
                <div class="stat">
                    <span class="stat-value">\(results.duplicateClusters.count)</span>
                    <span class="stat-label">Duplicate Clusters</span>
                </div>
                <div class="stat">
                    <span class="stat-value">\(results.totalDuplicates)</span>
                    <span class="stat-label">Total Duplicates</span>
                </div>
                <div class="stat">
                    <span class="stat-value">\(results.potentialSavings)%</span>
                    <span class="stat-label">Potential Savings</span>
                </div>
            </div>
            
            <h2>🔍 Duplicate Clusters</h2>
            \(results.duplicateClusters.enumerated().map { index, cluster in
                let oldestDate = cluster.oldestMemory?.timestamp ?? Date()
                let newestDate = cluster.newestMemory?.timestamp ?? Date()
                return """
                <div class="cluster">
                    <h3>Cluster \(index + 1)</h3>
                    <p>
                        <strong>Size:</strong> \(cluster.memories.count) memories | 
                        <strong>Similarity:</strong> \(Int(cluster.similarity * 100))% |
                        <span class="date-range">📅 \(dateFormatter.string(from: oldestDate)) → \(dateFormatter.string(from: newestDate))</span>
                    </p>
                    <h4>Suggested Merge:</h4>
                    <blockquote>\(cluster.suggestedMerge.replacingOccurrences(of: "\n", with: "<br>"))</blockquote>
                </div>
                """
            }.joined())
            
            \(!results.recommendations.isEmpty ? """
            <h2>💡 Recommendations</h2>
            \(results.recommendations.map { rec in
                """
                <div class="recommendation">
                    <strong>\(rec.title):</strong> \(rec.description)
                </div>
                """
            }.joined())
            """ : "")
            
            <hr style="margin-top: 50px; border: 1px solid #ecf0f1;">
            <p class="metadata" style="text-align: center;">
                Generated by Memory Defragmenter • <a href="https://github.com/yourusername/memory-defragmenter">View on GitHub</a>
            </p>
        </body>
        </html>
        """
    }
    
    private static func generatePDFReport(results: AnalysisResult, optimizedClusters: [MemoryCluster]) -> Data {
        let html = generateHTML(results)
        
        guard let data = html.data(using: .utf8) else {
            return Data()
        }
        
        do {
            let attributedString = try NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html,
                         .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil
            )
            
            // Create print info
            let printInfo = NSPrintInfo()
            printInfo.paperSize = NSSize(width: 612, height: 792) // US Letter
            printInfo.horizontalPagination = .fit
            printInfo.verticalPagination = .automatic
            printInfo.topMargin = 50
            printInfo.bottomMargin = 50
            printInfo.leftMargin = 50
            printInfo.rightMargin = 50
            
            // Create text storage and layout manager
            let textStorage = NSTextStorage(attributedString: attributedString)
            let layoutManager = NSLayoutManager()
            textStorage.addLayoutManager(layoutManager)
            
            // Create text container
            let textContainer = NSTextContainer(size: CGSize(
                width: printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin,
                height: printInfo.paperSize.height - printInfo.topMargin - printInfo.bottomMargin
            ))
            textContainer.widthTracksTextView = true
            layoutManager.addTextContainer(textContainer)
            
            // Create text view
            let textView = NSTextView(frame: NSRect(
                x: 0,
                y: 0,
                width: textContainer.size.width,
                height: textContainer.size.height
            ), textContainer: textContainer)
            
            // Generate PDF data
            let pdfData = NSMutableData()
            let printOperation = NSPrintOperation.pdfOperation(
                with: textView,
                inside: textView.bounds,
                to: pdfData,
                printInfo: printInfo
            )
            
            printOperation.showsPrintPanel = false
            printOperation.showsProgressPanel = false
            printOperation.run()
            
            return pdfData as Data
            
        } catch {
            print("PDF generation error: \(error)")
            return Data()
        }
    }
    
    @MainActor
    private static func showNotification(title: String, message: String, isError: Bool) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = isError ? .warning : .informational
        alert.addButton(withTitle: "OK")
        
        alert.runModal()
    }
}
