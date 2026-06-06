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

    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .environment(store)
        }
        .modelContainer(for: PlayerProgress.self)
    }
}
