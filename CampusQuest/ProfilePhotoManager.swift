//
//  ProfilePhotoManager.swift
//  CampusQuest
//
//  Created by Ömer Efe DİKİCİ.
//
//  Owns the player's avatar choice for signed-in (Apple) users. The
//  avatar can be one of three things, checked in priority order by
//  AvatarView:
//    1. A photo picked from the library (stored as JPEG Data).
//    2. A built-in, app-themed "generated" avatar (an academic SF Symbol
//       on a brand gradient) referenced by id.
//    3. Nothing — in which case a monogram fallback is shown.
//
//  Everything is kept in UserDefaults so the lightweight, AppStorage-based
//  AvatarView picks up changes automatically. No SwiftData, no networking.
//
//  PRIVACY: guests never get here — AvatarView always renders the "G"
//  monogram for guest sessions and ignores any stored value.
//

import SwiftUI
import PhotosUI

/// Keys shared between the manager and the AppStorage-backed views.
enum ProfilePhotoKeys {
    static let photoData = "profilePhotoData"
    static let avatarID = "profileAvatarID"
}

/// A built-in, app-themed avatar: an academic SF Symbol drawn on a brand
/// gradient. These are generated at render time (no image assets), so they
/// stay crisp at every size and match the CampusQuest look.
struct PresetAvatar: Identifiable, Hashable {
    let id: String
    let symbol: String
    let colors: [Color]

    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// The catalog of generated avatars, all themed around learning and
    /// computer-science topics to reflect the app.
    static let all: [PresetAvatar] = [
        PresetAvatar(id: "scholar",  symbol: "graduationcap.fill",
                     colors: [Color(red: 0.36, green: 0.52, blue: 0.96), Color(red: 0.55, green: 0.40, blue: 0.92)]),
        PresetAvatar(id: "bookworm", symbol: "book.fill",
                     colors: [Color(red: 0.20, green: 0.62, blue: 0.94), Color(red: 0.30, green: 0.40, blue: 0.90)]),
        PresetAvatar(id: "thinker",  symbol: "brain.head.profile",
                     colors: [Color(red: 0.95, green: 0.45, blue: 0.62), Color(red: 0.62, green: 0.36, blue: 0.92)]),
        PresetAvatar(id: "scientist", symbol: "atom",
                     colors: [Color(red: 0.18, green: 0.74, blue: 0.78), Color(red: 0.22, green: 0.48, blue: 0.92)]),
        PresetAvatar(id: "coder",    symbol: "chevron.left.forwardslash.chevron.right",
                     colors: [Color(red: 0.28, green: 0.34, blue: 0.55), Color(red: 0.44, green: 0.30, blue: 0.78)]),
        PresetAvatar(id: "spark",    symbol: "lightbulb.fill",
                     colors: [Color(red: 0.98, green: 0.70, blue: 0.30), Color(red: 0.96, green: 0.45, blue: 0.45)]),
        PresetAvatar(id: "explorer", symbol: "globe.americas.fill",
                     colors: [Color(red: 0.24, green: 0.70, blue: 0.55), Color(red: 0.20, green: 0.52, blue: 0.86)]),
        PresetAvatar(id: "launcher", symbol: "paperplane.fill",
                     colors: [Color(red: 0.55, green: 0.40, blue: 0.95), Color(red: 0.90, green: 0.42, blue: 0.74)]),
        PresetAvatar(id: "champion", symbol: "trophy.fill",
                     colors: [Color(red: 0.96, green: 0.62, blue: 0.20), Color(red: 0.92, green: 0.36, blue: 0.32)]),
        PresetAvatar(id: "puzzler",  symbol: "puzzlepiece.fill",
                     colors: [Color(red: 0.30, green: 0.66, blue: 0.92), Color(red: 0.52, green: 0.40, blue: 0.95)]),
        PresetAvatar(id: "starred",  symbol: "star.fill",
                     colors: [Color(red: 0.99, green: 0.78, blue: 0.28), Color(red: 0.95, green: 0.55, blue: 0.20)]),
        PresetAvatar(id: "function", symbol: "function",
                     colors: [Color(red: 0.22, green: 0.48, blue: 0.99), Color(red: 0.18, green: 0.72, blue: 0.80)]),
    ]

    static func preset(id: String?) -> PresetAvatar? {
        guard let id else { return nil }
        return all.first { $0.id == id }
    }
}

/// Reads and writes the avatar choice. Photos are saved as JPEG (0.8) and
/// selecting one clears any preset, and vice-versa, so only one source of
/// truth is active at a time.
@Observable
@MainActor
final class ProfilePhotoManager {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// The library photo, if one was picked.
    var savedPhoto: UIImage? {
        guard let data = defaults.data(forKey: ProfilePhotoKeys.photoData) else { return nil }
        return UIImage(data: data)
    }

    /// The currently selected built-in avatar, if any.
    var selectedPreset: PresetAvatar? {
        PresetAvatar.preset(id: defaults.string(forKey: ProfilePhotoKeys.avatarID))
    }

    /// The pixel size avatar photos are stored at. The avatar never renders
    /// larger than ~96pt (≈288px @3x), so 512 stays crisp with headroom while
    /// keeping the stored image tiny.
    private static let avatarPixelSize: CGFloat = 512

    /// Stores a freshly picked library photo and clears any preset.
    func save(image: UIImage) {
        // Downscale before encoding: a full-resolution library photo is several
        // megabytes, and UserDefaults is loaded wholesale into memory at launch
        // (and re-decoded on every avatar render). A small square cuts storage
        // from megabytes to tens of kilobytes with no visible quality loss.
        let prepared = image.squareCropped(toPixels: Self.avatarPixelSize)
        guard let data = prepared.jpegData(compressionQuality: 0.8) else { return }
        defaults.set(data, forKey: ProfilePhotoKeys.photoData)
        defaults.removeObject(forKey: ProfilePhotoKeys.avatarID)
    }

    /// Selects a built-in avatar and clears any library photo.
    func select(_ preset: PresetAvatar) {
        defaults.set(preset.id, forKey: ProfilePhotoKeys.avatarID)
        defaults.removeObject(forKey: ProfilePhotoKeys.photoData)
    }

    /// Clears both, falling back to the monogram.
    func reset() {
        defaults.removeObject(forKey: ProfilePhotoKeys.photoData)
        defaults.removeObject(forKey: ProfilePhotoKeys.avatarID)
    }
}

// MARK: - Image downscaling

private extension UIImage {
    /// Returns a square, center-cropped copy at most `pixels` on a side, drawn
    /// at scale 1 so the byte footprint matches the pixel size. Never upscales
    /// a smaller source. Orientation is normalised by the renderer.
    func squareCropped(toPixels pixels: CGFloat) -> UIImage {
        let side = min(size.width, size.height)
        let target = min(side, pixels)
        guard target > 0 else { return self }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: target, height: target), format: format)
        return renderer.image { _ in
            // Scale the whole image so its shorter side equals `target`, then
            // offset so the centered square lands in the output rect.
            let scale = target / side
            let drawSize = CGSize(width: size.width * scale, height: size.height * scale)
            let drawOrigin = CGPoint(x: (target - drawSize.width) / 2,
                                     y: (target - drawSize.height) / 2)
            draw(in: CGRect(origin: drawOrigin, size: drawSize))
        }
    }
}

// MARK: - Photo library picker

/// A thin SwiftUI wrapper around PHPickerViewController for picking a single
/// image (the modern, iOS 14+ API — no UIImagePickerController).
struct PhotoPicker: UIViewControllerRepresentable {
    var onPick: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { [parent] object, _ in
                guard let image = object as? UIImage else { return }
                Task { @MainActor in parent.onPick(image) }
            }
        }
    }
}
