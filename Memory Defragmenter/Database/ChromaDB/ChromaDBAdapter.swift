//
//  ChromaDBAdapter.swift
//  Memory Defragmenter
//
//  Created by Nicholas Rogers on 21.06.2025.
//

import Foundation

// MARK: - ChromaDB Adapter
/// Direct integration with ChromaDB using Python bridge
class ChromaDBAdapter {
    private let chromaPath: String
    private let pythonHelper: PythonBridge
    
    init(path: String) {
        self.chromaPath = path
        self.pythonHelper = PythonBridge()
    }
    
    // MARK: - Public Methods
    
    /// Load all memories directly from ChromaDB
    func loadMemories() async throws -> [MemoryRecord] {
        print("[ChromaDB] Starting to load memories from: \(chromaPath)")
        
        // Create a temporary file for the output
        let tempDir = FileManager.default.temporaryDirectory
        let outputFile = tempDir.appendingPathComponent("chromadb_output_\(UUID().uuidString).json")
        
        let script = """
        import sys
        import json
        import chromadb
        from datetime import datetime
        import numpy as np
        
        output_file = sys.argv[1]
        
        print("Loading ChromaDB...", file=sys.stderr)
        
        # Initialize ChromaDB client
        client = chromadb.PersistentClient(path='\(chromaPath)')
        collection = client.get_collection("memory_collection")
        
        print("Getting all memories from collection...", file=sys.stderr)
        
        # Get all memories
        results = collection.get(include=["metadatas", "documents", "embeddings"])
        
        print(f"Processing {len(results['ids'])} memories...", file=sys.stderr)
        
        memories = []
        for i, doc_id in enumerate(results['ids']):
            metadata = results['metadatas'][i]
            
            # Parse tags
            tags = []
            if 'tags' in metadata:
                import json as json_module
                try:
                    tags = json_module.loads(metadata['tags'])
                except:
                    tags = []
            
            # Convert embedding to list if it exists
            embedding = []
            if results.get('embeddings') is not None and len(results['embeddings']) > i:
                embedding = results['embeddings'][i]
                # Convert numpy array to list if needed
                if hasattr(embedding, 'tolist'):
                    embedding = embedding.tolist()
                elif isinstance(embedding, np.ndarray):
                    embedding = embedding.tolist()
            
            memory = {
                'id': doc_id,
                'content': results['documents'][i],
                'embedding': embedding,
                'metadata': metadata,
                'timestamp': metadata.get('timestamp', 0),
                'content_hash': metadata.get('content_hash', doc_id),
                'tags': tags
            }
            memories.append(memory)
        
        print(f"Finished processing, returning {len(memories)} memories", file=sys.stderr)
        
        # Write to file instead of stdout
        with open(output_file, 'w') as f:
            json.dump({
                'success': True,
                'count': len(memories),
                'memories': memories
            }, f)
        
        print("Output written to file", file=sys.stderr)
        """
        
        print("[ChromaDB] Executing Python script with output file...")
        let result = try await pythonHelper.execute(script, arguments: [outputFile.path])
        
        // Read the output file
        print("[ChromaDB] Reading output file...")
        let outputData = try Data(contentsOf: outputFile)
        defer { try? FileManager.default.removeItem(at: outputFile) }
        
        print("[ChromaDB] Read \(outputData.count) bytes from output file")
        
        guard let json = try? JSONSerialization.jsonObject(with: outputData) as? [String: Any] else {
            print("[ChromaDB] Failed to parse JSON from output file")
            throw ChromaDBError.loadFailed("Failed to parse JSON response")
        }
        
        guard let success = json["success"] as? Bool else {
            print("[ChromaDB] No success field in JSON: \(json.keys)")
            throw ChromaDBError.loadFailed("No success field in response")
        }
        
        guard success else {
            print("[ChromaDB] Success was false")
            throw ChromaDBError.loadFailed("Response indicated failure")
        }
        
        guard let memoriesArray = json["memories"] as? [[String: Any]] else {
            print("[ChromaDB] No memories array in JSON")
            throw ChromaDBError.loadFailed("No memories in response")
        }
        
        print("[ChromaDB] Found \(memoriesArray.count) memories to process")
        
        // Convert to MemoryRecord objects
        let records: [MemoryRecord] = memoriesArray.compactMap { dict in
            guard let id = dict["id"] as? String,
                  let content = dict["content"] as? String else { return nil }
            
            let embedding = (dict["embedding"] as? [Double])?.map { Float($0) } ?? []
            let metadata = dict["metadata"] as? [String: Any] ?? [:]
            let timestamp = dict["timestamp"] as? Double ?? 0
            let contentHash = dict["content_hash"] as? String ?? id
            let tags = dict["tags"] as? [String] ?? []
            
            // Convert metadata to string dictionary
            var stringMetadata: [String: String] = [:]
            for (key, value) in metadata {
                if let stringValue = value as? String {
                    stringMetadata[key] = stringValue
                } else {
                    stringMetadata[key] = "\(value)"
                }
            }
            
            // Add tags to metadata if not already there
            if !tags.isEmpty {
                stringMetadata["tags"] = tags.joined(separator: ", ")
            }
            
            return MemoryRecord(
                id: id,
                content: content,
                embedding: embedding,
                metadata: stringMetadata,
                timestamp: Date(timeIntervalSince1970: timestamp),
                contentHash: contentHash
            )
        }
        
        print("[ChromaDB] Successfully converted \(records.count) memory records")
        return records
    }
    
    /// Count memories in ChromaDB
    func countMemories() async throws -> Int {
        let script = """
        import chromadb
        client = chromadb.PersistentClient(path='\(chromaPath)')
        collection = client.get_collection("memory_collection")
        count = collection.count()
        print(count)
        """
        
        let result = try await pythonHelper.execute(script)
        return Int(result.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }
    
    /// Save optimized memories back to ChromaDB
    func saveOptimizedMemories(_ memories: [MemoryRecord], options: OptimizationOptions) async throws {
        print("[ChromaDB] Starting saveOptimizedMemories with \(memories.count) memories")
        
        // Create backup first
        let backupPath = try await createBackup()
        print("[ChromaDB] Created backup at: \(backupPath)")
        
        // Write memories to a temporary file instead of embedding in script
        let tempDir = FileManager.default.temporaryDirectory
        let memoriesFile = tempDir.appendingPathComponent("memories_to_save_\(UUID().uuidString).json")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let memoriesData = try encoder.encode(memories)
        try memoriesData.write(to: memoriesFile)
        defer { try? FileManager.default.removeItem(at: memoriesFile) }
        
        print("[ChromaDB] Wrote memories to temp file: \(memoriesFile.path)")
        
        let script = """
        import sys
        import json
        import chromadb
        import shutil
        from datetime import datetime
        
        memories_file = sys.argv[1]
        chroma_path = sys.argv[2]
        
        print(f"Loading memories from {memories_file}", file=sys.stderr)
        
        # Read memories from file
        with open(memories_file, 'r') as f:
            memories_data = json.load(f)
        
        print(f"Loaded {len(memories_data)} memories", file=sys.stderr)
        
        # Initialize ChromaDB client
        client = chromadb.PersistentClient(path=chroma_path)
        
        # Delete existing collection
        try:
            client.delete_collection("memory_collection")
        except:
            pass
        
        # Create new collection with same settings
        collection = client.create_collection(
            name="memory_collection",
            metadata={"hnsw:space": "cosine"}
        )
        
        # Prepare batch data
        ids = []
        documents = []
        embeddings = []
        metadatas = []
        
        for memory in memories_data:
            ids.append(memory['id'])
            documents.append(memory['content'])
            
            # Convert embedding if present
            if 'embedding' in memory and memory['embedding']:
                embeddings.append(memory['embedding'])
            
            # Prepare metadata
            metadata = memory.get('metadata', {})
            metadata['content_hash'] = memory.get('contentHash', memory['id'])
            metadata['timestamp'] = memory.get('timestamp', 0)
            
            # Store tags as JSON string
            tags = metadata.get('tags', '').split(', ') if 'tags' in metadata else []
            metadata['tags'] = json.dumps(tags)
            
            metadatas.append(metadata)
        
        print(f"Adding {len(ids)} memories to collection", file=sys.stderr)
        
        # Add to collection
        if embeddings:
            collection.add(
                ids=ids,
                documents=documents,
                embeddings=embeddings,
                metadatas=metadatas
            )
        else:
            collection.add(
                ids=ids,
                documents=documents,
                metadatas=metadatas
            )
        
        print(json.dumps({
            'success': True,
            'count': len(ids),
            'backup_path': '\(backupPath)'
        }))
        """
        
        print("[ChromaDB] Executing save script...")
        let result = try await pythonHelper.execute(script, arguments: [memoriesFile.path, chromaPath])
        
        // Verify success
        guard let data = result.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool,
              success else {
            throw ChromaDBError.saveFailed("Failed to save optimized memories")
        }
        
        print("Successfully saved \(memories.count) optimized memories to ChromaDB")
    }
    
    /// Create a timestamped backup of ChromaDB
    private func createBackup() async throws -> String {
        print("[ChromaDB Backup] Starting backup of: \(chromaPath)")
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: ".", with: "-")
        
        let backupPath = chromaPath + "_backup_\(timestamp)"
        print("[ChromaDB Backup] Backup will be created at: \(backupPath)")
        
        let script = """
        import shutil
        import sys
        
        try:
            print(f"Copying {sys.argv[1]} to {sys.argv[2]}", file=sys.stderr)
            shutil.copytree(sys.argv[1], sys.argv[2])
            print(sys.argv[2])  # Return the backup path
        except Exception as e:
            print(f"Backup failed: {e}", file=sys.stderr)
            sys.exit(1)
        """
        
        let result = try await pythonHelper.execute(script, arguments: [chromaPath, backupPath])
        print("[ChromaDB Backup] Backup completed successfully")
        return backupPath
    }
}

// MARK: - ChromaDB Error Types
enum ChromaDBError: LocalizedError {
    case pythonNotFound
    case chromaDBNotInstalled
    case loadFailed(String)
    case saveFailed(String)
    case backupFailed(String)
    case sandboxRestriction
    
    var errorDescription: String? {
        switch self {
        case .pythonNotFound:
            return "Python 3 is required but not found"
        case .chromaDBNotInstalled:
            return "ChromaDB Python package is not installed.\n\nTo install, run in Terminal:\npip3 install chromadb\n\nOr navigate to the Memory Defragmenter folder and run:\n./scripts/setup.sh"
        case .loadFailed(let message):
            return "Failed to load from ChromaDB: \(message)"
        case .saveFailed(let message):
            return "Failed to save to ChromaDB: \(message)"
        case .backupFailed(let message):
            return "Failed to create backup: \(message)"
        case .sandboxRestriction:
            return "ChromaDB integration requires Python access which is not available in the sandboxed app.\n\nPlease use the ChromaDB export workflow:\n1. Close this app\n2. Run: ./scripts/chromadb_workflow.sh\n3. Export your ChromaDB to SQLite\n4. Open the exported .db file in Memory Defragmenter\n\nAlternatively, you can use the non-sandboxed version from GitHub."
        }
    }
}

// MARK: - Python Bridge
class PythonBridge {
    
    /// Execute a Python script and return the output
    func execute(_ script: String, arguments: [String] = []) async throws -> String {
        // Check if Python is available
        let pythonPath = try await findPython()
        print("[DEBUG] Using Python at: \(pythonPath)")
        
        // Create temporary script file
        let tempDir = FileManager.default.temporaryDirectory
        let scriptURL = tempDir.appendingPathComponent("chromadb_script_\(UUID().uuidString).py")
        
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: scriptURL) }
        
        print("[DEBUG] Executing Python script...")
        
        // Execute Python script
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = [scriptURL.path] + arguments
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        let startTime = Date()
        try process.run()
        
        // Read output data in background to avoid pipe buffer overflow
        var outputData = Data()
        var errorData = Data()
        
        let outputQueue = DispatchQueue(label: "output.reader")
        let errorQueue = DispatchQueue(label: "error.reader")
        
        outputQueue.async {
            while true {
                let chunk = outputPipe.fileHandleForReading.availableData
                if chunk.isEmpty { break }
                outputData.append(chunk)
            }
        }
        
        errorQueue.async {
            while true {
                let chunk = errorPipe.fileHandleForReading.availableData
                if chunk.isEmpty { break }
                errorData.append(chunk)
            }
        }
        
        // Add a timeout check
        let timeoutSeconds: TimeInterval = 120  // Increased to 2 minutes
        var isTimedOut = false
        
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: timeoutSeconds)
            if process.isRunning {
                print("[DEBUG] Python script timed out after \(timeoutSeconds) seconds")
                process.terminate()
                isTimedOut = true
            }
        }
        
        process.waitUntilExit()
        
        // Wait for readers to finish
        outputQueue.sync {}
        errorQueue.sync {}
        
        let duration = Date().timeIntervalSince(startTime)
        print("[DEBUG] Python script completed in \(duration) seconds")
        print("[DEBUG] Python exit status: \(process.terminationStatus)")
        print("[DEBUG] Output data size: \(outputData.count) bytes")
        print("[DEBUG] Error data size: \(errorData.count) bytes")
        
        // Always print stderr output for debugging
        if !errorData.isEmpty {
            let stderrString = String(data: errorData, encoding: .utf8) ?? ""
            if !stderrString.isEmpty {
                print("[Python stderr]: \(stderrString)")
            }
        }
        
        if process.terminationStatus != 0 {
            let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            
            // Check for specific Python errors
            if errorString.contains("ModuleNotFoundError") && errorString.contains("chromadb") {
                throw ChromaDBError.chromaDBNotInstalled
            }
            
            throw ChromaDBError.loadFailed("Python error: \(errorString)")
        }
        
        return String(data: outputData, encoding: .utf8) ?? ""
    }
    
    /// Find Python executable
    private func findPython() async throws -> String {
        print("[DEBUG] Starting Python search...")
        let candidates = [
            "/opt/homebrew/bin/python3.11",  // Homebrew Python 3.11 (where ChromaDB is installed)
            "/opt/homebrew/bin/python3.12",  // Homebrew Python 3.12
            "/opt/homebrew/bin/python3",     // Generic Homebrew Python (if exists)
            "/usr/local/bin/python3",        // Then usr/local (Intel Macs)
            "/usr/bin/python3",               // Then system Python
            "/opt/local/bin/python3",
            "/usr/bin/python",
            "/usr/local/bin/python",
            "/opt/homebrew/bin/python",
            "/System/Library/Frameworks/Python.framework/Versions/Current/bin/python3"
        ]
        
        print("[DEBUG] Will check \(candidates.count) Python paths")
        
        for path in candidates {
            if FileManager.default.fileExists(atPath: path) {
                print("[DEBUG] Checking Python at: \(path)")
                // Verify it's actually Python by checking if we can run it
                let testProcess = Process()
                testProcess.executableURL = URL(fileURLWithPath: path)
                testProcess.arguments = ["--version"]
                
                let testPipe = Pipe()
                testProcess.standardOutput = testPipe
                testProcess.standardError = testPipe
                
                do {
                    try testProcess.run()
                    testProcess.waitUntilExit()
                    
                    if testProcess.terminationStatus == 0 {
                        print("[DEBUG] Found working Python at: \(path)")
                        
                        // Test if ChromaDB is available in this Python
                        let chromaTest = Process()
                        chromaTest.executableURL = URL(fileURLWithPath: path)
                        chromaTest.arguments = ["-c", "import chromadb; print('ChromaDB OK')"]
                        
                        let chromaPipe = Pipe()
                        chromaTest.standardOutput = chromaPipe
                        chromaTest.standardError = chromaPipe
                        
                        try chromaTest.run()
                        chromaTest.waitUntilExit()
                        
                        if chromaTest.terminationStatus == 0 {
                            print("[DEBUG] ChromaDB is available in this Python")
                            return path
                        } else {
                            let errorData = chromaPipe.fileHandleForReading.readDataToEndOfFile()
                            let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown"
                            print("[DEBUG] ChromaDB not available in \(path): \(errorString)")
                        }
                    }
                } catch {
                    print("[DEBUG] Failed to test Python at \(path): \(error)")
                    // This python path didn't work, try next
                    continue
                }
            } else {
                print("[DEBUG] Python not found at: \(path)")
            }
        }
        
        print("[DEBUG] No Python found with ChromaDB. Paths checked: \(candidates.count)")
        throw ChromaDBError.pythonNotFound
    }
}

// MARK: - Extensions for Codable
// Note: MemoryRecord already conforms to Codable in its definition in Models.swift
