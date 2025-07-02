//
//  Memory_DefragmenterApp.swift
//  Memory Defragmenter
//
//  Created by Pineapple 🍍 on 11.06.2025.
//

import SwiftUI

@main
struct Memory_DefragmenterApp: App {
    @AppStorage("lastDatabasePath") private var lastDatabasePath = ""
    @StateObject private var appModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 800)
        .commands {
            // Custom menu commands
            CommandGroup(replacing: .appInfo) {
                Button("About Memory Defragmenter") {
                    appModel.showAboutWindow = true
                }
            }
            
            CommandGroup(after: .newItem) {
                Button("Open Database...") {
                    appModel.openDatabase()
                }
                .keyboardShortcut("O", modifiers: .command)
            }
        }
    }
}
