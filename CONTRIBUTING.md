# Contributing to Memory Defragmenter

First off, thank you for considering contributing to Memory Defragmenter! It's people like you that make Memory Defragmenter such a great tool for the MCP community.

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title** for the issue to identify the problem.
* **Describe the exact steps which reproduce the problem** in as many details as possible.
* **Provide specific examples to demonstrate the steps**.
* **Describe the behavior you observed after following the steps** and point out what exactly is the problem with that behavior.
* **Explain which behavior you expected to see instead and why.**
* **Include screenshots and animated GIFs** which show you following the described steps and clearly demonstrate the problem.
* **Include your system details** (macOS version, Xcode version, etc.)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title** for the issue to identify the suggestion.
* **Provide a step-by-step description of the suggested enhancement** in as many details as possible.
* **Provide specific examples to demonstrate the steps**.
* **Describe the current behavior** and **explain which behavior you expected to see instead** and why.
* **Include screenshots and animated GIFs** which help demonstrate the steps or the enhancement.
* **Explain why this enhancement would be useful** to most Memory Defragmenter users.

### Pull Requests

* Fill in the required template
* Do not include issue numbers in the PR title
* Follow the Swift style guide
* Include thoughtfully-worded, well-structured tests
* Document new code
* End all files with a newline

## Development Process

1. **Fork & Clone**: Fork the repo and clone it locally
2. **Branch**: Create a new branch for your feature/fix
3. **Code**: Make your changes following our coding standards
4. **Test**: Add/update tests as needed
5. **Commit**: Use clear commit messages
6. **Push**: Push your branch to your fork
7. **PR**: Submit a pull request

## Swift Style Guide

### Code Formatting

* Use 4 spaces for indentation (not tabs)
* Maximum line length of 120 characters
* Use descriptive variable names
* Follow Swift API Design Guidelines

### Example:
```swift
// Good
func analyzeMemoryDatabase(at path: String) throws -> AnalysisResult {
    guard FileManager.default.fileExists(atPath: path) else {
        throw DatabaseError.fileNotFound
    }
    // Implementation
}

// Bad
func analyze(_ p: String) -> Result? {
    // Implementation
}
```

### Documentation

* Use triple-slash comments for public APIs
* Include parameter descriptions
* Add usage examples for complex functions

```swift
/// Analyzes a Memory MCP database for duplicate entries
/// - Parameter path: The file path to the SQLite database
/// - Returns: An AnalysisResult containing duplicate clusters
/// - Throws: DatabaseError if the file cannot be read
func analyzeMemoryDatabase(at path: String) throws -> AnalysisResult
```

## Testing

### Unit Tests

* Write tests for all new functionality
* Maintain code coverage above 80%
* Use descriptive test names

```swift
func testAnalysisFindsExactDuplicates() throws {
    // Test implementation
}
```

### UI Tests

* Test critical user workflows
* Include both happy path and error scenarios
* Use accessibility identifiers for UI elements

## Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line

### Examples:
```
Add PDF export functionality for analysis reports

- Implement NSPrintOperation for PDF generation
- Add export menu with multiple format options
- Include unit tests for export manager

Fixes #123
```

## Project Structure

```
Memory Defragmenter/
├── Models/           # Data models and structures
│   └── Models.swift  # Core data types
├── Views/            # SwiftUI views
│   ├── ContentView.swift
│   └── StatisticsView.swift
├── ViewModels/       # View models and business logic
│   └── AppViewModel.swift
├── Services/         # Core services
│   ├── AnalysisEngine.swift
│   ├── OptimizationEngine.swift
│   ├── BackupManager.swift
│   └── ExportManager.swift
├── Database/         # Database operations
│   └── MemoryDatabase.swift
└── Assets.xcassets/  # Images and resources
```

## Questions?

Feel free to open an issue with the tag "question" if you have any questions about contributing.

Thank you for your contributions! 🎉
