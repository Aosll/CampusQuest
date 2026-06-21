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
    @State private var language = LanguageManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(auth)
                .environment(language)
                // Apply the chosen language app-wide and rebuild the tree when
                // it changes so every screen updates immediately.
                .environment(\.locale, language.locale)
                .id(language.resolvedCode)
        }
    }
}

/// The authentication gate. Lives in a real View (not the Scene body) so
/// that @Observable state changes reliably re-render the tree:
/// signed out -> login screen, otherwise the main menu.
///
/// The SwiftData container is chosen by auth state: signed-in players use
/// the on-disk store, guests use a fresh in-memory store so their progress
/// is never written to disk.
struct RootView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(ContentStore.self) private var store

    var body: some View {
        if case .signedOut = auth.state {
            LoginView()
        } else if store.department == nil {
            // No active major yet — first launch (or content still loading).
            // Force a major choice before the home screen appears.
            MajorOnboardingView()
                .modelContainer(auth.activeContainer)
        } else {
            MainMenuView()
                .modelContainer(auth.activeContainer)
        }
    }
}
