//
//  SecurityAndLogicTests.swift
//  CampusQuestTests
//
//  White-box unit tests. These reach into the app's internal types
//  (`@testable import`) to verify the security-sensitive auth/storage
//  behaviour and the core progress scoring logic directly — not through
//  the UI.
//

import XCTest
import UIKit
import SwiftData
@testable import CampusQuest

// MARK: - Auth & storage (security-sensitive)

@MainActor
final class AuthManagerTests: XCTestCase {

    /// A throwaway UserDefaults so tests never touch the real app domain.
    private func freshDefaults() -> UserDefaults {
        let name = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    func testGuestIsInMemoryAndFlagged() {
        let auth = AuthManager(defaults: freshDefaults())
        auth.continueAsGuest()
        XCTAssertTrue(auth.isGuest)
        XCTAssertEqual(auth.studentName, "Guest")
        XCTAssertNotNil(auth.guestContainer)
    }

    func testSignInPersistsAndRestores() {
        let defaults = freshDefaults()
        AuthManager(defaults: defaults).signInApple(userID: "U123", displayName: "Ada Lovelace")

        // A fresh instance must restore the same signed-in identity.
        let restored = AuthManager(defaults: defaults)
        guard case .signedInApple(let id, let name) = restored.state else {
            return XCTFail("Expected signedInApple after restore")
        }
        XCTAssertEqual(id, "U123")
        XCTAssertEqual(name, "Ada Lovelace")
    }

    /// The headline privacy fix: signing out must wipe the profile photo
    /// (PII) and avatar, not just the auth keys.
    func testSignOutClearsAuthAndProfilePII() {
        let defaults = freshDefaults()
        defaults.set(Data([0x01, 0x02, 0x03]), forKey: ProfilePhotoKeys.photoData)
        defaults.set("scholar", forKey: ProfilePhotoKeys.avatarID)

        let auth = AuthManager(defaults: defaults)
        auth.signInApple(userID: "U1", displayName: "X")
        auth.signOut()

        XCTAssertNil(defaults.data(forKey: ProfilePhotoKeys.photoData),
                     "Profile photo (PII) must be cleared on sign-out")
        XCTAssertNil(defaults.string(forKey: ProfilePhotoKeys.avatarID),
                     "Avatar selection must be cleared on sign-out")
        XCTAssertNil(defaults.string(forKey: "auth.appleUserID"))
        if case .signedOut = auth.state {} else { XCTFail("Expected signedOut") }
    }

    /// Two different Apple accounts must never see each other's progress.
    func testProgressIsolatedPerAccount() throws {
        let auth = AuthManager(defaults: freshDefaults())
        let userA = "A-\(UUID().uuidString)"
        let userB = "B-\(UUID().uuidString)"

        auth.signInApple(userID: userA, displayName: "A")
        let ctxA = ModelContext(auth.activeContainer)
        let progressA = PlayerProgress.current(in: ctxA)
        progressA.totalXP = 999
        try ctxA.save()

        auth.signOut()
        auth.signInApple(userID: userB, displayName: "B")
        let ctxB = ModelContext(auth.activeContainer)
        let progressB = PlayerProgress.current(in: ctxB)

        XCTAssertEqual(progressB.totalXP, 0,
                       "User B must start fresh, not inherit User A's progress")
    }

    /// Legacy single-store progress is handed to the FIRST signed-in user
    /// only; later accounts start clean. (Uses fresh defaults so the
    /// one-time migration flag starts unset.)
    func testLegacyMigrationOnlyFirstUserInherits() throws {
        let auth = AuthManager(defaults: freshDefaults())

        // Seed the legacy (shared default) store with a recognisable value.
        let legacyCtx = ModelContext(auth.fallbackContainer)
        let legacy = PlayerProgress.current(in: legacyCtx)
        let marker = Int.random(in: 10_000...99_999)
        legacy.totalXP = marker
        try legacyCtx.save()

        // First user inherits.
        auth.signInApple(userID: "first-\(UUID().uuidString)", displayName: "1")
        let firstXP = PlayerProgress.current(in: ModelContext(auth.activeContainer)).totalXP
        XCTAssertEqual(firstXP, marker, "First signed-in user should inherit legacy progress")

        // Second user does not.
        auth.signOut()
        auth.signInApple(userID: "second-\(UUID().uuidString)", displayName: "2")
        let secondXP = PlayerProgress.current(in: ModelContext(auth.activeContainer)).totalXP
        XCTAssertEqual(secondXP, 0, "Later users must not inherit the legacy progress")
    }
}

// MARK: - Appearance mapping (pure)

final class AppAppearanceTests: XCTestCase {
    func testUIStyleMapping() {
        XCTAssertEqual(AppAppearance.system.uiStyle, .unspecified)
        XCTAssertEqual(AppAppearance.light.uiStyle, .light)
        XCTAssertEqual(AppAppearance.dark.uiStyle, .dark)
    }

    func testColorSchemeMapping() {
        XCTAssertNil(AppAppearance.system.colorScheme)
        XCTAssertEqual(AppAppearance.light.colorScheme, .light)
        XCTAssertEqual(AppAppearance.dark.colorScheme, .dark)
    }
}

// MARK: - Progress scoring (core logic)

@MainActor
final class PlayerProgressTests: XCTestCase {

    private func inMemoryContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: PlayerProgress.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ModelContext(container)
    }

    func testLevelCompletionAwardsXPOnce() throws {
        let p = PlayerProgress.current(in: try inMemoryContext())

        let first = p.recordCompletion(levelTitle: "L1", wordCount: 5, totalLevels: 20)
        XCTAssertNotNil(first)
        XCTAssertEqual(p.totalXP, 5 * 10 + 50)
        XCTAssertTrue(p.isCompleted("L1"))

        let again = p.recordCompletion(levelTitle: "L1", wordCount: 5, totalLevels: 20)
        XCTAssertNil(again, "Replaying a finished level must not grant XP again")
        XCTAssertEqual(p.totalXP, 100, "XP must be unchanged on repeat")
    }

    func testQuizAwardsTenXPPerCorrect() throws {
        let p = PlayerProgress.current(in: try inMemoryContext())
        let xp = p.recordQuizFinished(correctCount: 3)
        XCTAssertEqual(xp, 30)
        XCTAssertEqual(p.quizCorrectTotal, 3)
    }

    func testSpendXPRespectsBalance() throws {
        let p = PlayerProgress.current(in: try inMemoryContext())
        p.totalXP = 50
        XCTAssertTrue(p.spendXP(30))
        XCTAssertEqual(p.totalXP, 20)
        XCTAssertFalse(p.spendXP(100), "Cannot overspend")
        XCTAssertEqual(p.totalXP, 20)
    }

    func testStreakStartsAtOne() throws {
        let p = PlayerProgress.current(in: try inMemoryContext())
        p.updateStreakForToday()
        XCTAssertEqual(p.currentStreak, 1)
        XCTAssertEqual(p.longestStreak, 1)
    }

    func testDailyChallengeClaimsOncePerDay() throws {
        let p = PlayerProgress.current(in: try inMemoryContext())
        let granted = p.claimDailyChallenge(reward: 75, progress: 5, target: 5)
        XCTAssertEqual(granted, 75)
        let again = p.claimDailyChallenge(reward: 75, progress: 5, target: 5)
        XCTAssertEqual(again, 0, "Daily reward is claimable only once per day")
    }
}
