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

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.state = restore()
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
        state = .signedInApple(userID: userID, displayName: name)
        persist()
    }

    func continueAsGuest() {
        state = .guest
        persist()
    }

    func signOut() {
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
