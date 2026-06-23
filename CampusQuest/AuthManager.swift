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
import AuthenticationServices
import CryptoKit

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
        /// Set once the legacy single shared store has been handed to the first
        /// signed-in user, so no later account inherits it.
        static let legacyMigrated = "progress.legacyMigrated"
    }

    private let defaults: UserDefaults

    /// The current auth state. Persisted on every change.
    private(set) var state: AuthState = .signedOut

    /// On-disk SwiftData stores, one per signed-in Apple user. Each account
    /// gets its own store file so progress never leaks between users sharing a
    /// device. Built lazily and cached for the app's lifetime so the same
    /// store isn't reopened on every access.
    @ObservationIgnored
    private var userContainers: [String: ModelContainer] = [:]

    /// Fallback on-disk store used only when no specific user is active (e.g.
    /// the signed-out gate, where no progress views are shown anyway).
    @ObservationIgnored
    private(set) lazy var fallbackContainer: ModelContainer = {
        do {
            return try ModelContainer(for: PlayerProgress.self)
        } catch {
            fatalError("Could not create fallback ModelContainer: \(error)")
        }
    }()

    /// In-memory SwiftData store used by guests. Recreated fresh for every
    /// guest session so a guest ALWAYS starts from scratch and nothing is
    /// ever written to disk (see PRIVACY RULE above).
    @ObservationIgnored
    private(set) var guestContainer: ModelContainer?

    /// The container the rest of the app should use for the current state.
    /// Signed-in users get their own per-account on-disk store; guests get the
    /// in-memory store; the signed-out gate falls back to a default store.
    var activeContainer: ModelContainer {
        switch state {
        case .guest:
            return guestContainer ?? fallbackContainer
        case .signedInApple(let userID, _):
            return container(forUserID: userID)
        case .signedOut:
            return fallbackContainer
        }
    }

    /// Returns (building and caching on first use) the on-disk store for a
    /// specific Apple user.
    private func container(forUserID userID: String) -> ModelContainer {
        if let existing = userContainers[userID] { return existing }
        // Detect a brand-new store *before* opening it (opening creates the file).
        let isNewStore = !FileManager.default.fileExists(
            atPath: Self.storeURL(forUserID: userID).path)
        let container = Self.makePersistentContainer(forUserID: userID)
        userContainers[userID] = container
        if isNewStore {
            migrateLegacyProgressIfNeeded(into: container)
        }
        return container
    }

    /// One-time migration. The app used to keep a single shared on-disk store
    /// for every signed-in user. The FIRST Apple user to sign in after the
    /// per-account split inherits that legacy progress — copied field-by-field
    /// into their own store (not a file move, so SwiftData's -wal/-shm sidecar
    /// files are never mishandled). Later users start fresh. The legacy store
    /// is intentionally left in place as a safety net.
    private func migrateLegacyProgressIfNeeded(into container: ModelContainer) {
        // Mark up front so this can only ever run for one user, even if the
        // copy below fails partway: the legacy store stays intact as backup.
        guard !defaults.bool(forKey: Keys.legacyMigrated) else { return }
        defaults.set(true, forKey: Keys.legacyMigrated)

        let legacyContext = ModelContext(fallbackContainer)
        guard let legacy = try? legacyContext.fetch(FetchDescriptor<PlayerProgress>()).first else {
            return // No previous progress to carry over (e.g. fresh install).
        }

        let context = ModelContext(container)
        let copy = PlayerProgress.current(in: context) // creates the record if needed
        copy.totalXP = legacy.totalXP
        copy.completedLevels = legacy.completedLevels
        copy.earnedBadges = legacy.earnedBadges
        copy.wordsFound = legacy.wordsFound
        copy.bestPerfectLab = legacy.bestPerfectLab
        copy.quizCorrectTotal = legacy.quizCorrectTotal
        copy.currentStreak = legacy.currentStreak
        copy.longestStreak = legacy.longestStreak
        copy.lastPlayedDay = legacy.lastPlayedDay
        copy.dailyDay = legacy.dailyDay
        copy.dailyWords = legacy.dailyWords
        copy.dailyXP = legacy.dailyXP
        copy.dailyLevels = legacy.dailyLevels
        copy.dailyChallengeClaimedDay = legacy.dailyChallengeClaimedDay
        copy.lastDailyCompletedDate = legacy.lastDailyCompletedDate
        try? context.save()
    }

    /// Builds the per-user on-disk container at a stable, user-specific URL.
    private static func makePersistentContainer(forUserID userID: String) -> ModelContainer {
        let config = ModelConfiguration(url: storeURL(forUserID: userID))
        do {
            return try ModelContainer(for: PlayerProgress.self, configurations: config)
        } catch {
            fatalError("Could not create persistent ModelContainer: \(error)")
        }
    }

    /// Filesystem location of a user's store, inside Application Support. The
    /// Apple userID isn't filesystem-safe, so the file name is derived from a
    /// stable hash of it (the raw userID never lands on disk as a name).
    private static func storeURL(forUserID userID: String) -> URL {
        let support = URL.applicationSupportDirectory
        // SwiftData expects the containing directory to exist.
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        return support.appendingPathComponent("Progress-\(fileToken(for: userID)).store")
    }

    /// A stable, filesystem-safe token for a userID (truncated SHA-256 hex).
    private static func fileToken(for userID: String) -> String {
        SHA256.hash(data: Data(userID.utf8)).prefix(16)
            .map { String(format: "%02x", $0) }
            .joined()
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
        // Privacy: the avatar photo is personal data (PII). Drop it (and the
        // chosen preset) on sign-out so a different account signing in on a
        // shared device can't inherit the previous player's photo or identity.
        defaults.removeObject(forKey: ProfilePhotoKeys.photoData)
        defaults.removeObject(forKey: ProfilePhotoKeys.avatarID)
    }

    /// Re-validates a persisted Apple sign-in against the system on launch.
    ///
    /// A stored `appleUserID` is otherwise trusted forever — but the user can
    /// revoke the app's access at any time (Settings ▸ Apple ID ▸ Sign in with
    /// Apple), or the credential can be transferred/removed. Apple requires
    /// checking the credential state so a session that is no longer valid does
    /// not silently stay signed in. No-op for guests and signed-out users.
    func revalidateAppleCredentialIfNeeded() async {
        guard case .signedInApple(let userID, _) = state else { return }

        let provider = ASAuthorizationAppleIDProvider()
        let credentialState: ASAuthorizationAppleIDProvider.CredentialState =
            await withCheckedContinuation { continuation in
                provider.getCredentialState(forUserID: userID) { state, _ in
                    continuation.resume(returning: state)
                }
            }

        switch credentialState {
        case .authorized:
            break // Still valid — keep the session.
        case .revoked, .notFound, .transferred:
            // Access pulled, account gone, or migrated: drop the local session.
            signOut()
        @unknown default:
            break
        }
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
