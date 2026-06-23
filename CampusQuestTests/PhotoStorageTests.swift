//
//  PhotoStorageTests.swift
//  CampusQuestTests
//
//  Verifies the avatar-photo storage optimisation: a large library photo
//  must be downscaled to a small square before it lands in UserDefaults,
//  so it never bloats launch memory or the prefs store.
//

import XCTest
import UIKit
@testable import CampusQuest

@MainActor
final class PhotoStorageTests: XCTestCase {

    /// Builds a high-entropy image (random tiles) so its JPEG size scales with
    /// pixel count — a flat colour would compress to almost nothing and hide
    /// the effect of downscaling.
    private func makeNoisyImage(width: CGFloat, height: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: width, height: height), format: format)
        return renderer.image { ctx in
            let tile: CGFloat = 40
            var y: CGFloat = 0
            while y < height {
                var x: CGFloat = 0
                while x < width {
                    UIColor(red: .random(in: 0...1),
                            green: .random(in: 0...1),
                            blue: .random(in: 0...1),
                            alpha: 1).setFill()
                    ctx.fill(CGRect(x: x, y: y, width: tile, height: tile))
                    x += tile
                }
                y += tile
            }
        }
    }

    func testLargePhotoIsDownscaledOnSave() throws {
        let defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        let manager = ProfilePhotoManager(defaults: defaults)

        // A realistic full-resolution library photo (~12 MP).
        let source = makeNoisyImage(width: 3000, height: 4000)
        let sourceBytes = source.jpegData(compressionQuality: 0.8)!.count

        manager.save(image: source)

        let stored = try XCTUnwrap(defaults.data(forKey: ProfilePhotoKeys.photoData),
                                   "save(image:) must persist the photo")
        let storedBytes = stored.count
        let decoded = try XCTUnwrap(UIImage(data: stored))

        // The stored avatar must be a small square, not the original.
        XCTAssertEqual(decoded.size.width, decoded.size.height, "Avatar should be square")
        XCTAssertLessThanOrEqual(max(decoded.size.width, decoded.size.height), 512,
                                 "Avatar must be capped at 512px")
        XCTAssertLessThan(storedBytes, 200_000,
                          "Downscaled avatar should be well under 200 KB")
        XCTAssertLessThan(storedBytes, sourceBytes / 4,
                          "Downscaled avatar should be far smaller than the source")

        // Recorded for the test log: source vs. stored size and final dimensions.
        print("📸 Avatar storage — source ~\(sourceBytes / 1024) KB "
              + "→ stored \(storedBytes / 1024) KB "
              + "(\(Int(decoded.size.width))×\(Int(decoded.size.height)))")
    }

    /// A photo already smaller than the cap must not be upscaled.
    func testSmallPhotoIsNotUpscaled() throws {
        let defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        let manager = ProfilePhotoManager(defaults: defaults)

        manager.save(image: makeNoisyImage(width: 200, height: 200))

        let stored = try XCTUnwrap(defaults.data(forKey: ProfilePhotoKeys.photoData))
        let decoded = try XCTUnwrap(UIImage(data: stored))
        XCTAssertLessThanOrEqual(max(decoded.size.width, decoded.size.height), 200,
                                 "A small source must not be upscaled")
    }
}
