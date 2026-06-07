//
//  CampusQuestApp.swift
//  CampusQuest
//
//  App entry point. Creates the shared ContentStore and sets up the
//  SwiftData container so progress is saved on the device.
//

import SwiftUI
import SwiftData

@main
struct CampusQuestApp: App {
    // Created once for the whole app; shared with all child views.
    @State private var store = ContentStore()
    @State private var auth = AuthManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(auth)
        }
        .modelContainer(for: PlayerProgress.self)
    }
}

/// The authentication gate. Lives in a real View (not the Scene body) so
/// that @Observable state changes reliably re-render the tree:
/// signed out -> login screen, otherwise the main menu.
struct RootView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        if case .signedOut = auth.state {
            LoginView()
        } else {
            MainMenuView()
        }
    }
}
