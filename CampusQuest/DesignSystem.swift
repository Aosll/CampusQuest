//
//  DesignSystem.swift
//  CampusQuest
//
//  A single source of truth for the app's "Soft Campus Glassmorphism"
//  look: semantic colors, corner radii, and reusable surfaces. Using
//  these everywhere keeps the UI consistent and easy to extend.
//

import SwiftUI

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

    /// Deep indigo for primary text on light backgrounds.
    static let ink = Color(red: 0.16, green: 0.18, blue: 0.40)
    /// Muted blue-grey for secondary text.
    static let inkSecondary = Color(red: 0.38, green: 0.42, blue: 0.56)
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

extension LinearGradient {
    /// The app's primary blue → purple gradient (buttons, logos, accents).
    static let brand = LinearGradient(
        colors: [AppColor.primary, AppColor.secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// The soft blue-lavender page background gradient.
    static let pageBackground = LinearGradient(
        colors: [
            Color(red: 0.82, green: 0.91, blue: 1.00),
            Color(red: 0.93, green: 0.89, blue: 0.99)
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
                    .fill(Color.white.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
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
