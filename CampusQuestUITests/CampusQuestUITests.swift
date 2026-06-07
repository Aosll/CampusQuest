//
//  CampusQuestUITests.swift
//  CampusQuestUITests
//
//  Created by Ömer Efe DİKİCİ on 5.06.2026.
//

import XCTest

final class CampusQuestUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testQuizDoneReturnsToMainMenu() throws {
        let app = XCUIApplication()
        app.launch()

        // The app launches into the login gate; continue as guest to reach
        // the main menu.
        let guestButton = app.buttons["Continue as Guest"]
        if guestButton.waitForExistence(timeout: 5) {
            guestButton.tap()
        }

        let categories = ["Programming Fundamentals", "Data Structures",
                          "Computer Networks", "Databases", "Cybersecurity"]

        // Open the quiz from the home screen.
        XCTAssertTrue(app.buttons["Quiz"].waitForExistence(timeout: 5))
        app.buttons["Quiz"].tap()

        // Play through every question, always picking the first available option.
        for _ in 0..<12 {
            // If we've reached the results, stop.
            if app.buttons["Done"].exists { break }

            // Tap the first visible answer option.
            var tappedAnswer = false
            for category in categories {
                let option = app.buttons.containing(
                    NSPredicate(format: "label CONTAINS[c] %@", category)
                ).firstMatch
                if option.exists && option.isHittable {
                    option.tap()
                    tappedAnswer = true
                    break
                }
            }

            // Advance to the next question / results.
            let next = app.buttons["Next Question"].exists
                ? app.buttons["Next Question"]
                : app.buttons["See Results"]
            if next.waitForExistence(timeout: 3) {
                next.tap()
            } else if !tappedAnswer {
                break
            }
        }

        // On the results screen, tap Done.
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5),
                      "Results screen with Done button should appear")
        app.buttons["Done"].tap()

        // We should be back on the main menu (its Quiz tile is visible again).
        XCTAssertTrue(app.buttons["Quiz"].waitForExistence(timeout: 5),
                      "Tapping Done should return to the main menu")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
