//
//  LabSceneView.swift
//  CampusQuest
//
//  Step 3 UI upgrade: a 2.5D / isometric lab scene that builds up as
//  the player finds words. Each correct word turns one visual module on.
//

import SwiftUI

struct LabSceneView: View {
    let levelTitle: String
    let totalWords: Int
    let foundCount: Int

    var body: some View {
        let theme = LabTheme.forLevel(levelTitle)
        let safeTotal = max(totalWords, 1)
        let progress = min(max(Double(foundCount) / Double(safeTotal), 0), 1)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: theme.icon)
                    .foregroundStyle(theme.accent)
                Text(theme.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColor.ink)
                Spacer()
                Text("\(foundCount)/\(totalWords) completed")
                    .font(.caption.bold())
                    .foregroundStyle(AppColor.inkSecondary)
            }

            ZStack {
                IsoLabBackdrop(theme: theme)

                IsoScreen(
                    title: theme.screenTitle,
                    icon: theme.screenIcon,
                    isOnline: foundCount >= 1,
                    accent: theme.accent
                )
                .offset(x: -70, y: -34)

                IsoServerRack(
                    isOnline: foundCount >= max(2, safeTotal / 3),
                    accent: theme.accent
                )
                .offset(x: 78, y: -22)

                IsoDesk(accent: theme.accent)
                    .offset(y: 36)

                IsoTerminalBlock(
                    icon: theme.primaryObjectIcon,
                    isOnline: foundCount >= max(1, safeTotal / 2),
                    accent: theme.accent
                )
                .offset(x: -42, y: 32)

                IsoCoreModule(
                    symbol: theme.coreSymbol,
                    isOnline: foundCount >= safeTotal - 1,
                    accent: theme.accent
                )
                .offset(x: 54, y: 42)

                ForEach(0..<safeTotal, id: \.self) { index in
                    FloatingModule(
                        symbol: theme.symbols[index % theme.symbols.count],
                        isOnline: index < foundCount,
                        accent: theme.accent
                    )
                    .offset(moduleOffset(index: index))
                }

                if foundCount == totalWords && totalWords > 0 {
                    CompletionGlow(accent: theme.accent)
                }
            }
            .frame(height: 184)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(theme.accent.opacity(0.24), lineWidth: 1)
            )

            ProgressView(value: progress)
                .tint(theme.accent)
        }
        .padding(14)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: theme.accent.opacity(0.12), radius: 14, y: 6)
        .animation(.spring(response: 0.42, dampingFraction: 0.72), value: foundCount)
    }

    private func moduleOffset(index: Int) -> CGSize {
        let positions: [CGSize] = [
            CGSize(width: -112, height: 58),
            CGSize(width: -88, height: 8),
            CGSize(width: -36, height: -72),
            CGSize(width: 18, height: -82),
            CGSize(width: 84, height: -70),
            CGSize(width: 118, height: -10),
            CGSize(width: 108, height: 58),
            CGSize(width: 20, height: 76),
            CGSize(width: -70, height: 78),
            CGSize(width: 0, height: -26)
        ]
        return positions[index % positions.count]
    }
}

// MARK: - Scene pieces

private struct IsoLabBackdrop: View {
    let theme: LabTheme
    /// Gentle idle "breathing" so the scene feels alive even before any
    /// module is online.
    @State private var breathe = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [theme.backgroundTop, theme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Path { path in
                path.move(to: CGPoint(x: 24, y: 22))
                path.addLine(to: CGPoint(x: 300, y: 22))
                path.addLine(to: CGPoint(x: 278, y: 125))
                path.addLine(to: CGPoint(x: 46, y: 125))
                path.closeSubpath()
            }
            .fill(.white.opacity(0.38))

            Path { path in
                path.move(to: CGPoint(x: 46, y: 125))
                path.addLine(to: CGPoint(x: 278, y: 125))
                path.addLine(to: CGPoint(x: 326, y: 190))
                path.addLine(to: CGPoint(x: -4, y: 190))
                path.closeSubpath()
            }
            .fill(.white.opacity(0.46))

            ForEach(0..<5, id: \.self) { i in
                Path { path in
                    let y = 136 + CGFloat(i) * 12
                    path.move(to: CGPoint(x: 32 - CGFloat(i) * 14, y: y))
                    path.addLine(to: CGPoint(x: 292 + CGFloat(i) * 14, y: y))
                }
                .stroke(theme.ink.opacity(0.08), lineWidth: 1)
            }

            Circle()
                .fill(theme.accent.opacity(breathe ? 0.26 : 0.14))
                .frame(width: 150, height: 150)
                .blur(radius: 38)
                .offset(x: 94, y: -72)
                .scaleEffect(breathe ? 1.08 : 0.94)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }
}

private struct IsoScreen: View {
    let title: String
    let icon: String
    let isOnline: Bool
    let accent: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3.bold())
            Text(title)
                .font(.system(size: 8, weight: .bold, design: .rounded))
        }
        .foregroundStyle(isOnline ? Color.white : Color.secondary.opacity(0.55))
        .frame(width: 86, height: 52)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isOnline ? accent : Color.white.opacity(0.56))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isOnline ? Color.white.opacity(0.55) : Color.secondary.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: isOnline ? accent.opacity(0.35) : .black.opacity(0.04), radius: isOnline ? 10 : 4, y: 4)
        .scaleEffect(isOnline ? 1.03 : 0.96)
    }
}

private struct IsoServerRack: View {
    let isOnline: Bool
    let accent: Color

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { _ in
                HStack(spacing: 5) {
                    Circle()
                        .fill(isOnline ? accent : Color.secondary.opacity(0.22))
                        .frame(width: 6, height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isOnline ? accent.opacity(0.75) : Color.secondary.opacity(0.18))
                        .frame(width: 38, height: 5)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(isOnline ? 0.82 : 0.52), in: RoundedRectangle(cornerRadius: 7))
            }
        }
        .padding(7)
        .background(Color.black.opacity(isOnline ? 0.16 : 0.08), in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: isOnline ? accent.opacity(0.25) : .black.opacity(0.04), radius: 9, y: 4)
    }
}

private struct IsoDesk: View {
    let accent: Color

    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 62, y: 18))
                path.addLine(to: CGPoint(x: 220, y: 18))
                path.addLine(to: CGPoint(x: 258, y: 52))
                path.addLine(to: CGPoint(x: 24, y: 52))
                path.closeSubpath()
            }
            .fill(.white.opacity(0.84))
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: 62, y: 18))
                    path.addLine(to: CGPoint(x: 220, y: 18))
                    path.addLine(to: CGPoint(x: 258, y: 52))
                    path.addLine(to: CGPoint(x: 24, y: 52))
                    path.closeSubpath()
                }
                .stroke(accent.opacity(0.18), lineWidth: 1)
            )

            RoundedRectangle(cornerRadius: 5)
                .fill(Color.black.opacity(0.10))
                .frame(width: 12, height: 42)
                .offset(x: -82, y: 42)
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.black.opacity(0.10))
                .frame(width: 12, height: 42)
                .offset(x: 84, y: 42)
        }
        .frame(width: 282, height: 92)
    }
}

private struct IsoTerminalBlock: View {
    let icon: String
    let isOnline: Bool
    let accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13)
                .fill(isOnline ? Color.black.opacity(0.68) : Color.white.opacity(0.72))
                .frame(width: 74, height: 48)
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .strokeBorder(isOnline ? accent.opacity(0.7) : Color.secondary.opacity(0.15), lineWidth: 1)
                )

            Image(systemName: icon)
                .font(.title3.bold())
                .foregroundStyle(isOnline ? accent : Color.secondary.opacity(0.45))
        }
        .shadow(color: isOnline ? accent.opacity(0.30) : .black.opacity(0.04), radius: isOnline ? 10 : 4, y: 4)
        .scaleEffect(isOnline ? 1.04 : 0.96)
    }
}

private struct IsoCoreModule: View {
    let symbol: String
    let isOnline: Bool
    let accent: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(isOnline ? accent.opacity(0.22) : Color.white.opacity(0.60))
                .frame(width: 64, height: 64)
            Circle()
                .strokeBorder(isOnline ? accent : Color.secondary.opacity(0.18), lineWidth: 3)
                .frame(width: 50, height: 50)
            Image(systemName: symbol)
                .font(.title3.bold())
                .foregroundStyle(isOnline ? accent : Color.secondary.opacity(0.45))
        }
        .shadow(color: isOnline ? accent.opacity(0.32) : .black.opacity(0.04), radius: isOnline ? 12 : 4, y: 4)
        .scaleEffect(isOnline ? 1.08 : 0.94)
    }
}

private struct FloatingModule: View {
    let symbol: String
    let isOnline: Bool
    let accent: Color

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(isOnline ? Color.white : Color.secondary.opacity(0.42))
            .frame(width: 30, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(isOnline ? accent : Color.white.opacity(0.58))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(isOnline ? Color.white.opacity(0.55) : Color.secondary.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: isOnline ? accent.opacity(0.30) : .black.opacity(0.03), radius: isOnline ? 8 : 3, y: 3)
            .scaleEffect(isOnline ? 1.08 : 0.82)
            .opacity(isOnline ? 1 : 0.55)
    }
}

private struct CompletionGlow: View {
    let accent: Color

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(accent.opacity(0.26), lineWidth: 8)
                .frame(width: 160, height: 160)
                .blur(radius: 2)
            Image(systemName: "sparkles")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(accent)
                .offset(x: 0, y: -76)
        }
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Per-level theme

private struct LabTheme {
    let title: String
    let icon: String
    let screenTitle: String
    let screenIcon: String
    let primaryObjectIcon: String
    let coreSymbol: String
    let symbols: [String]
    let accent: Color
    let ink: Color
    let backgroundTop: Color
    let backgroundBottom: Color

    static func forLevel(_ levelTitle: String) -> LabTheme {
        let ink = Color(red: 0.18, green: 0.20, blue: 0.42)

        // Numbered titles ("Computer Networks 2") map to their base category.
        let category = ["Programming Fundamentals", "Data Structures",
                        "Computer Networks", "Databases", "Cybersecurity"]
            .first { levelTitle.hasPrefix($0) } ?? levelTitle

        switch category {
        case "Programming Fundamentals":
            return LabTheme(
                title: "Programming Lab",
                icon: "curlybraces",
                screenTitle: "CODE",
                screenIcon: "terminal.fill",
                primaryObjectIcon: "chevron.left.forwardslash.chevron.right",
                coreSymbol: "function",
                symbols: ["curlybraces", "function", "terminal", "number", "textformat", "keyboard", "arrow.triangle.2.circlepath"],
                accent: Color(red: 0.16, green: 0.58, blue: 0.98),
                ink: ink,
                backgroundTop: Color(red: 0.78, green: 0.90, blue: 1.0),
                backgroundBottom: Color(red: 0.92, green: 0.94, blue: 1.0)
            )
        case "Data Structures":
            return LabTheme(
                title: "Data Structures Lab",
                icon: "square.stack.3d.up",
                screenTitle: "STACK",
                screenIcon: "square.stack.3d.up.fill",
                primaryObjectIcon: "tray.full.fill",
                coreSymbol: "point.3.connected.trianglepath.dotted",
                symbols: ["square.stack.3d.up.fill", "tray.full.fill", "list.bullet.indent", "circle.grid.3x3", "square.stack.fill", "tray.2.fill"],
                accent: Color(red: 0.42, green: 0.35, blue: 0.92),
                ink: ink,
                backgroundTop: Color(red: 0.86, green: 0.84, blue: 1.0),
                backgroundBottom: Color(red: 0.95, green: 0.92, blue: 1.0)
            )
        case "Computer Networks":
            return LabTheme(
                title: "Network Lab",
                icon: "network",
                screenTitle: "LINK",
                screenIcon: "network",
                primaryObjectIcon: "wifi",
                coreSymbol: "antenna.radiowaves.left.and.right",
                symbols: ["network", "wifi", "server.rack", "globe", "cable.connector", "externaldrive.connected.to.line.below"],
                accent: Color(red: 0.06, green: 0.68, blue: 0.64),
                ink: ink,
                backgroundTop: Color(red: 0.77, green: 0.97, blue: 0.94),
                backgroundBottom: Color(red: 0.91, green: 0.98, blue: 1.0)
            )
        case "Databases":
            return LabTheme(
                title: "Database Lab",
                icon: "cylinder.split.1x2",
                screenTitle: "DATA",
                screenIcon: "cylinder.split.1x2.fill",
                primaryObjectIcon: "tablecells",
                coreSymbol: "externaldrive.fill",
                symbols: ["tablecells", "cylinder.split.1x2", "cylinder", "externaldrive", "tray.full", "list.bullet.rectangle", "square.grid.3x3"],
                accent: Color(red: 0.98, green: 0.56, blue: 0.18),
                ink: ink,
                backgroundTop: Color(red: 1.0, green: 0.91, blue: 0.80),
                backgroundBottom: Color(red: 1.0, green: 0.96, blue: 0.90)
            )
        case "Cybersecurity":
            return LabTheme(
                title: "Security Lab",
                icon: "lock.shield",
                screenTitle: "SAFE",
                screenIcon: "lock.shield.fill",
                primaryObjectIcon: "key.fill",
                coreSymbol: "checkmark.shield.fill",
                symbols: ["lock.shield", "shield.lefthalf.filled", "key", "exclamationmark.shield", "bolt.shield", "ladybug", "lock.fill", "checkmark.shield"],
                accent: Color(red: 0.18, green: 0.76, blue: 0.34),
                ink: ink,
                backgroundTop: Color(red: 0.82, green: 0.96, blue: 0.86),
                backgroundBottom: Color(red: 0.91, green: 0.98, blue: 0.93)
            )
        default:
            return LabTheme(
                title: "Campus Lab",
                icon: "cpu",
                screenTitle: "LAB",
                screenIcon: "cpu.fill",
                primaryObjectIcon: "memorychip",
                coreSymbol: "sparkles",
                symbols: ["cpu", "memorychip", "server.rack", "network", "terminal", "externaldrive", "lock.shield", "tablecells"],
                accent: Color.accentColor,
                ink: ink,
                backgroundTop: Color(red: 0.84, green: 0.91, blue: 1.0),
                backgroundBottom: Color(red: 0.95, green: 0.92, blue: 1.0)
            )
        }
    }
}

#Preview {
    VStack {
        LabSceneView(levelTitle: "Programming Fundamentals", totalWords: 8, foundCount: 3)
        LabSceneView(levelTitle: "Cybersecurity", totalWords: 8, foundCount: 8)
    }
    .padding()
}
