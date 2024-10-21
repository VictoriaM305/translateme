import SwiftUI
import Firebase

@main
struct TranslateMeApp: App {
    
    // Initialize Firebase when the app launches
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView() // This links to your ContentView.swift
        }
    }
}

