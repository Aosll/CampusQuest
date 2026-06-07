//
//  AuthManager.swift
//  CampusQuest
//
//  Holds the current authentication state and persists the user's choice
//  so they are not asked to sign in on every launch. This step is local
//  only: no CloudKit, Game Center, or networking. Progress remains in
//  SwiftData on the device.
//
//  PRIVACY RULE: When the state is `.guest`, the app must NOT collect or
//  store any statistics or analytics of any kind. Any tracking added in
//  the future must check `isGuest` and skip entirely while in guest mode.
//

import Foundation
import Observation
import SwiftData

/// The possible authentication states for the app.
enum AuthState: Equatable {
    case signedInApple(userID: String, displayName: String)
    case guest
    case signedOut
}

@Observable
@MainActor
final class AuthManager {
    private enum Keys {
        static let appleUserID = "auth.appleUserID"
        static let displayName = "auth.displayName"
        static let isGuest = "auth.isGuest"
    }

    private let defaults: UserDefaults

    /// The current auth state. Persisted on every change.
    private(set) var state: AuthState = .signedOut

    /// On-disk SwiftData store used by signed-in (Apple) players. Created
    /// once and kept for the app's lifetime.
    @ObservationIgnored
    private(set) lazy var persistentContainer: ModelContainer = {
        do {
            return try ModelContainer(for: PlayerProgress.self)
        } catch {
            fatalError("Could not create persistent ModelContainer: \(error)")
        }
    }()

    /// In-memory SwiftData store used by guests. Recreated fresh for every
    /// guest session so a guest ALWAYS starts from scratch and nothing is
    /// ever written to disk (see PRIVACY RULE above).
    @ObservationIgnored
    private(set) var guestContainer: ModelContainer?

    /// The container the rest of the app should use for the current state.
    var activeContainer: ModelContainer {
        if case .guest = state, let guestContainer { return guestContainer }
        return persistentContainer
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let restored = restore()
        self.state = restored
        // A restored guest session still gets a brand-new in-memory store.
        if case .guest = restored {
            self.guestContainer = Self.makeGuestContainer()
        }
    }

    /// Builds a fresh in-memory container (no on-disk persistence).
    private static func makeGuestContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: PlayerProgress.self, configurations: config)
        } catch {
            fatalError("Could not create in-memory ModelContainer: \(error)")
        }
    }

    // MARK: - Derived

    /// True while the user is browsing as a guest. Stats/analytics must be
    /// skipped entirely when this is true (see PRIVACY RULE above).
    var isGuest: Bool {
        if case .guest = state { return true }
        return false
    }

    /// Name to show in the UI: the Apple display name, or "Guest".
    var studentName: String {
        switch state {
        case .signedInApple(_, let name): return name
        case .guest:                      return "Guest"
        case .signedOut:                  return "Player"
        }
    }

    // MARK: - Actions

    /// Sign in with an Apple credential. The name is only returned by Apple
    /// on the first authorization, so we persist it the first time and reuse
    /// the stored value on later sign-ins.
    func signInApple(userID: String, displayName: String?) {
        let storedName = defaults.string(forKey: Keys.displayName)
        let name = displayName ?? storedName ?? "Student"
        // Drop any leftover guest store so its in-memory data is released.
        guestContainer = nil
        state = .signedInApple(userID: userID, displayName: name)
        persist()
    }

    func continueAsGuest() {
        // Fresh in-memory store every time: each guest starts from zero.
        guestContainer = Self.makeGuestContainer()
        state = .guest
        persist()
    }

    func signOut() {
        // Releasing the in-memory store discards all guest progress.
        guestContainer = nil
        state = .signedOut
        defaults.removeObject(forKey: Keys.appleUserID)
        defaults.removeObject(forKey: Keys.displayName)
        defaults.removeObject(forKey: Keys.isGuest)
    }

    // MARK: - Persistence

    private func restore() -> AuthState {
        if let userID = defaults.string(forKey: Keys.appleUserID), !userID.isEmpty {
            let name = defaults.string(forKey: Keys.displayName) ?? "Student"
            return .signedInApple(userID: userID, displayName: name)
        }
        if defaults.bool(forKey: Keys.isGuest) {
            return .guest
        }
        return .signedOut
    }

    private func persist() {
        switch state {
        case .signedInApple(let userID, let name):
            defaults.set(userID, forKey: Keys.appleUserID)
            defaults.set(name, forKey: Keys.displayName)
            defaults.set(false, forKey: Keys.isGuest)
        case .guest:
            defaults.set(true, forKey: Keys.isGuest)
            defaults.removeObject(forKey: Keys.appleUserID)
        case .signedOut:
            defaults.removeObject(forKey: Keys.appleUserID)
            defaults.removeObject(forKey: Keys.displayName)
            defaults.removeObject(forKey: Keys.isGuest)
        }
    }
}
