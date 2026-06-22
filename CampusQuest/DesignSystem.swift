//
//  DesignSystem.swift
//  CampusQuest
//
//  A single source of truth for the app's "Soft Campus Glassmorphism"
//  look: semantic colors, corner radii, and reusable surfaces. Using
//  these everywhere keeps the UI consistent and easy to extend.
//

import SwiftUI
import UIKit

/// The user's in-app appearance preference. "system" follows the device
/// setting; "light"/"dark" force a fixed scheme regardless of the system.
/// Persisted via `@AppStorage(AppAppearance.storageKey)`.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark

    static let storageKey = "appearancePreference"

    var id: String { rawValue }

    /// The scheme to force, or `nil` to follow the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var displayName: String {
        switch self {
        case .system: return String(localized: "System")
        case .light:  return String(localized: "Light")
        case .dark:   return String(localized: "Dark")
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }

    /// The matching UIKit style. `.unspecified` follows the system.
    var uiStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    /// Forces the chosen appearance directly on the app's window(s).
    ///
    /// We drive `overrideUserInterfaceStyle` at the window level instead of
    /// relying only on SwiftUI's `.preferredColorScheme`: that modifier doesn't
    /// reliably propagate into presented sheets, so picking Dark from the
    /// Settings sheet would sometimes leave that sheet stuck in Light. The
    /// window override covers the whole app — sheets, alerts, everything.
    func applyToWindows() {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = uiStyle
            }
        }
    }
}

/// Builds a color that resolves differently in light and dark mode.
/// Keeping this in one helper means every adaptive color reads the same way.
private func adaptiveColor(
    light: (CGFloat, CGFloat, CGFloat, CGFloat),
    dark: (CGFloat, CGFloat, CGFloat, CGFloat)
) -> Color {
    Color(uiColor: UIColor { trait in
        let c = trait.userInterfaceStyle == .dark ? dark : light
        return UIColor(red: c.0, green: c.1, blue: c.2, alpha: c.3)
    })
}

/// Semantic color palette. Colors carry meaning (success, locked, …),
/// not just decoration, so screens stay coherent as the app grows.
enum AppColor {
    /// Vivid blue — primary actions and active states.
    static let primary = Color(red: 0.22, green: 0.48, blue: 0.99)
    /// Purple — secondary accents and gradients.
    static let secondary = Color(red: 0.52, green: 0.40, blue: 0.95)
    /// Green — success, completion, correct answers.
    static let success = Color(red: 0.18, green: 0.76, blue: 0.40)
    /// Warm orange — warnings and "review this" hints.
    static let warning = Color(red: 0.98, green: 0.58, blue: 0.20)
    /// Soft grey — locked / disabled surfaces.
    static let locked = Color(red: 0.62, green: 0.65, blue: 0.74)

    /// Primary text: deep indigo on light, near-white on dark.
    static let ink = adaptiveColor(
        light: (0.16, 0.18, 0.40, 1),
        dark:  (0.93, 0.95, 1.00, 1)
    )
    /// Secondary text: muted blue-grey, lighter in dark mode.
    static let inkSecondary = adaptiveColor(
        light: (0.38, 0.42, 0.56, 1),
        dark:  (0.66, 0.70, 0.82, 1)
    )
    /// Frosted card surface — translucent white on light, dark slate on dark.
    /// Alpha is baked in so cards keep their soft glassy look in both modes.
    static let surface = adaptiveColor(
        light: (1.00, 1.00, 1.00, 0.90),
        dark:  (0.16, 0.18, 0.26, 0.92)
    )
    /// Slightly stronger surface for locked/secondary cards.
    static let surfaceMuted = adaptiveColor(
        light: (1.00, 1.00, 1.00, 0.72),
        dark:  (0.16, 0.18, 0.26, 0.70)
    )
}

/// Standard type scale so headings, cards, and labels stay consistent.
enum AppFont {
    /// Big home/hero title.
    static let hero = Font.system(size: 36, weight: .heavy, design: .rounded)
    /// Screen-level title.
    static let screenTitle = Font.system(size: 26, weight: .semibold, design: .rounded)
    /// Card title.
    static let cardTitle = Font.system(size: 21, weight: .semibold)
    /// Body / description text.
    static let body = Font.system(size: 15, weight: .regular)
    /// Small uppercase status labels (DONE / NEXT / LOCKED).
    static let tag = Font.system(size: 12, weight: .bold)
}

/// Standard corner radii so every surface uses the same rounding scale.
enum AppRadius {
    static let modal: CGFloat = 32
    static let largeCard: CGFloat = 28
    static let card: CGFloat = 22
    static let control: CGFloat = 18
    static let icon: CGFloat = 16
}

/// Shared per-course color + icon coding, used across the level map and
/// dictionary so each subject reads with the same identity everywhere.
/// Matches by category prefix so numbered titles ("Databases 2") resolve.
enum CoursePalette {
    static func color(for title: String) -> Color {
        if title.hasPrefix("Programming Fundamentals") { return AppColor.primary }                 // blue
        if title.hasPrefix("Data Structures")          { return AppColor.secondary }              // purple
        if title.hasPrefix("Computer Networks")        { return AppColor.success }                // green
        if title.hasPrefix("Databases")                { return AppColor.warning }                // orange
        if title.hasPrefix("Cybersecurity")            { return Color(red: 0.90, green: 0.27, blue: 0.31) } // red
        return AppColor.primary
    }

    static func icon(for title: String) -> String {
        if title.hasPrefix("Programming Fundamentals") { return "terminal.fill" }
        if title.hasPrefix("Data Structures")          { return "square.stack.3d.up.fill" }
        if title.hasPrefix("Computer Networks")        { return "network" }
        if title.hasPrefix("Databases")                { return "cylinder.split.1x2.fill" }
        if title.hasPrefix("Cybersecurity")            { return "lock.shield.fill" }
        return "graduationcap.fill"
    }
}

/// Heuristic word difficulty from length (no per-word data needed).
enum WordDifficulty {
    static func label(for word: String) -> (text: String, color: Color) {
        switch word.count {
        case ...5:  return ("Easy", AppColor.success)
        case 6...8: return ("Medium", AppColor.warning)
        default:    return ("Hard", Color(red: 0.90, green: 0.27, blue: 0.31))
        }
    }
}

extension LinearGradient {
    /// The app's primary blue → purple gradient (buttons, logos, accents).
    static let brand = LinearGradient(
        colors: [AppColor.primary, AppColor.secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// The soft blue-lavender page background gradient (dark navy on dark mode).
    static let pageBackground = LinearGradient(
        colors: [
            adaptiveColor(light: (0.82, 0.91, 1.00, 1), dark: (0.07, 0.09, 0.16, 1)),
            adaptiveColor(light: (0.93, 0.89, 0.99, 1), dark: (0.10, 0.08, 0.17, 1))
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// A reusable frosted-glass surface used by cards across the app.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = AppRadius.card
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppColor.surface.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
    }
}

/// A lightweight press style: the control scales down and dims slightly
/// while pressed, giving every tappable surface a tactile, game-like feel.
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// A faint dotted "QR / circuit" decoration used on the ID card and
/// major cards to reinforce the tech-campus theme.
struct DotPattern: View {
    var columns = 5
    var rows = 5
    var dot: CGFloat = 3
    var spacing: CGFloat = 7
    var color: Color = .white

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<rows, id: \.self) { r in
                HStack(spacing: spacing) {
                    ForEach(0..<columns, id: \.self) { c in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(color.opacity((r + c).isMultiple(of: 2) ? 0.9 : 0.35))
                            .frame(width: dot, height: dot)
                    }
                }
            }
        }
    }
}
