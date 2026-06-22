//
//  LevelSelectView.swift
//  CampusQuest
//
//  Step 2 UI upgrade: turns the level list into a campus quest map.
//  Completed rooms glow, the next playable room is highlighted, and
//  later rooms remain locked until the previous level is completed.
//

import SwiftUI
import SwiftData
import UIKit

struct LevelSelectView: View {
    let department: Department

    @Query private var progressList: [PlayerProgress]
    private var progress: PlayerProgress? { progressList.first }

    private let ink = AppColor.ink

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                CampusMapBanner(
                    departmentName: department.name,
                    completedCount: completedCount,
                    totalCount: department.levels.count
                )
                .padding(.horizontal)
                .padding(.top, 12)

                VStack(spacing: 0) {
                    ForEach(Array(department.levels.enumerated()), id: \.element.id) { index, level in
                        let completed = isCompleted(level)
                        let unlocked = isUnlocked(index: index)
                        let state: RoomState = completed ? .completed : (unlocked ? .available : .locked)

                        VStack(spacing: 0) {
                            if index > 0 {
                                LevelPathConnector(
                                    isActive: isUnlocked(index: index),
                                    curveToRight: !index.isMultiple(of: 2)
                                )
                            }

                            if unlocked {
                                NavigationLink {
                                    LevelView(
                                        level: level,
                                        totalLevels: department.levels.count,
                                        nextLevel: index + 1 < department.levels.count ? department.levels[index + 1] : nil
                                    )
                                } label: {
                                    LevelRoomCard(
                                        number: index + 1,
                                        level: level,
                                        roomName: roomName(for: level.title),
                                        icon: roomIcon(for: level.title),
                                        courseColor: CoursePalette.color(for: level.title),
                                        xpReward: xpReward(for: level),
                                        state: state,
                                        alignment: index.isMultiple(of: 2) ? .leading : .trailing
                                    )
                                }
                                .buttonStyle(PressableButtonStyle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                })
                            } else {
                                LevelRoomCard(
                                    number: index + 1,
                                    level: level,
                                    roomName: roomName(for: level.title),
                                    icon: roomIcon(for: level.title),
                                    courseColor: CoursePalette.color(for: level.title),
                                    xpReward: xpReward(for: level),
                                    state: state,
                                    alignment: index.isMultiple(of: 2) ? .leading : .trailing
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .background(CampusMapBackground().ignoresSafeArea())
        .navigationTitle(department.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Progress logic

    private var completedCount: Int {
        department.levels.filter { isCompleted($0) }.count
    }

    private func isCompleted(_ level: GameLevel) -> Bool {
        progress?.isCompleted(level.title) ?? false
    }

    /// First level is always open; each next level opens when the previous one is completed.
    private func isUnlocked(index: Int) -> Bool {
        if index == 0 { return true }
        let previous = department.levels[index - 1]
        return progress?.isCompleted(previous.title) ?? false
    }

    /// A campus-flavored "room" name for each course, so the map reads
    /// like a journey through buildings rather than a plain course list.
    /// Matches by category prefix so numbered titles ("Programming
    /// Fundamentals 2") keep a readable room name with their part number.
    private func roomName(for title: String) -> String {
        if let (base, suffix) = roomBase(for: title) {
            return suffix.isEmpty ? base : "\(base) \(suffix)"
        }
        return title
    }

    private func roomBase(for title: String) -> (String, String)? {
        let rooms: [(String, String)] = [
            ("Programming Fundamentals", "Programming Lab"),
            ("Data Structures",          "Data Structures Lab"),
            ("Computer Networks",        "Network Room"),
            ("Databases",                "Database Archive"),
            ("Cybersecurity",            "Security Operations Center"),
        ]
        for (category, room) in rooms where title.hasPrefix(category) {
            let suffix = title.dropFirst(category.count).trimmingCharacters(in: .whitespaces)
            return (room, suffix)
        }
        return nil
    }

    private func roomIcon(for title: String) -> String {
        CoursePalette.icon(for: title)
    }

    /// XP a level awards on first completion (matches PlayerProgress).
    private func xpReward(for level: GameLevel) -> Int {
        level.words.count * 10 + 50
    }
}

// MARK: - Campus banner

private struct CampusMapBanner: View {
    let departmentName: String
    let completedCount: Int
    let totalCount: Int

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.38, green: 0.55, blue: 0.98),
                            Color(red: 0.60, green: 0.42, blue: 0.94)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 92))
                        .foregroundStyle(.white.opacity(0.16))
                        .rotationEffect(.degrees(-12))
                        .offset(x: 18, y: -8)
                }
                .overlay(alignment: .top) {
                    HStack(spacing: 14) {
                        miniBuilding(icon: "curlybraces")
                        miniBuilding(icon: "server.rack")
                        miniBuilding(icon: "lock.shield")
                    }
                    .padding(.top, 16)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text("Campus Map")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.78))

                Text(departmentName)
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("\(completedCount) / \(totalCount) rooms completed")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.84))
            }
            .padding(20)
        }
        .frame(height: 190)
        .shadow(color: .black.opacity(0.14), radius: 14, y: 7)
    }

    private func miniBuilding(icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3.bold())
                .foregroundStyle(Color.accentColor)
                .frame(width: 48, height: 42)
                .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 12))

            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.72))
                .frame(width: 62, height: 34)
        }
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
    }
}

// MARK: - Quest path

enum RoomState {
    case completed
    case available
    case locked
}

/// A winding "campus path" between two rooms. It swings toward the side
/// the next card sits on, drawn as a dashed curve with a walking marker.
private struct LevelPathConnector: View {
    let isActive: Bool
    /// True when the path should curve toward the trailing (right) side.
    var curveToRight: Bool = true

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let startX = curveToRight ? w * 0.35 : w * 0.65
            let endX = curveToRight ? w * 0.65 : w * 0.35
            let ctrlX = curveToRight ? w * 0.85 : w * 0.15

            let path = Path { p in
                p.move(to: CGPoint(x: startX, y: 0))
                p.addQuadCurve(
                    to: CGPoint(x: endX, y: h),
                    control: CGPoint(x: ctrlX, y: h * 0.5)
                )
            }

            ZStack {
                // Soft wide base for depth.
                path.stroke(
                    isActive ? AppColor.primary.opacity(0.18) : Color.secondary.opacity(0.10),
                    style: StrokeStyle(lineWidth: 9, lineCap: .round)
                )
                // Smooth solid route on top.
                path.stroke(
                    isActive
                        ? AnyShapeStyle(LinearGradient.brand)
                        : AnyShapeStyle(Color.secondary.opacity(0.28)),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )

                Image(systemName: isActive ? "figure.walk" : "lock.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isActive ? AppColor.primary : Color.secondary.opacity(0.45))
                    .padding(5)
                    .background(.white, in: Circle())
                    .shadow(color: .black.opacity(0.10), radius: 3, y: 1)
                    .position(x: ctrlX, y: h * 0.5)
            }
        }
        .frame(height: 50)
    }
}

private struct LevelRoomCard: View {
    let number: Int
    let level: GameLevel
    let roomName: String
    let icon: String
    let courseColor: Color
    let xpReward: Int
    let state: RoomState
    let alignment: HorizontalAlignment

    private let ink = AppColor.ink

    var body: some View {
        HStack {
            if alignment == .trailing {
                Spacer(minLength: 28)
            }

            HStack(spacing: 14) {
                roomThumbnail

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text("Level \(number)")
                            .font(.caption.bold())
                            .foregroundStyle(statusColor)

                        statusPill
                    }

                    Text(roomName)
                        .font(AppFont.cardTitle)
                        .foregroundStyle(state == .locked ? ink.opacity(0.45) : ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Text("\(level.title) · \(level.words.count) words")
                        .font(.caption)
                        .foregroundStyle(ink.opacity(0.55))
                        .lineLimit(1)

                    // XP reward badge.
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                        Text("\(xpReward) XP")
                    }
                    .font(.caption2.bold())
                    .foregroundStyle(state == .completed ? AppColor.success : courseColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        (state == .completed ? AppColor.success : courseColor).opacity(0.12),
                        in: Capsule()
                    )
                }

                Spacer(minLength: 8)

                Image(systemName: trailingIcon)
                    .font(.title3.bold())
                    .foregroundStyle(statusColor)
            }
            .padding(14)
            .frame(maxWidth: 330)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(borderColor, lineWidth: state == .available ? 1.8 : 1)
            )
            .shadow(
                color: shadowColor,
                radius: state == .available ? 13 : 6,
                y: state == .available ? 6 : 3
            )
            .opacity(state == .locked ? 0.62 : 1)
            .blur(radius: state == .locked ? 0.8 : 0)
            .scaleEffect(state == .available ? 1.015 : 1)

            if alignment == .leading {
                Spacer(minLength: 28)
            }
        }
    }

    private var roomThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(thumbnailGradient)
                .frame(width: 68, height: 68)

            Image(systemName: state == .locked ? "lock.fill" : icon)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(state == .locked ? Color.secondary : Color.white)

            if state == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Color.white)
                    .background(Color.green, in: Circle())
                    .offset(x: 25, y: -25)
            }
        }
    }

    private var statusPill: some View {
        Text(statusText)
            .font(AppFont.tag)
            .tracking(0.8)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .foregroundStyle(statusColor)
            .background(statusColor.opacity(0.12), in: Capsule())
    }

    private var statusText: String {
        switch state {
        case .completed:
            return "DONE"
        case .available:
            return "NEXT"
        case .locked:
            return "LOCKED"
        }
    }

    private var trailingIcon: String {
        switch state {
        case .completed:
            return "checkmark.circle.fill"
        case .available:
            return "arrow.right.circle.fill"
        case .locked:
            return "lock.fill"
        }
    }

    private var statusColor: Color {
        switch state {
        case .completed:
            return AppColor.success
        case .available:
            return courseColor
        case .locked:
            return .secondary
        }
    }

    private var cardBackground: Color {
        switch state {
        case .completed, .available:
            return AppColor.surface
        case .locked:
            return AppColor.surfaceMuted
        }
    }

    private var borderColor: Color {
        switch state {
        case .completed:
            return AppColor.success.opacity(0.30)
        case .available:
            return courseColor.opacity(0.5)
        case .locked:
            return .secondary.opacity(0.14)
        }
    }

    private var shadowColor: Color {
        switch state {
        case .completed:
            return AppColor.success.opacity(0.12)
        case .available:
            return courseColor.opacity(0.28)
        case .locked:
            return .black.opacity(0.04)
        }
    }

    private var thumbnailGradient: LinearGradient {
        switch state {
        case .completed:
            return LinearGradient(
                colors: [AppColor.success, courseColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .available:
            return LinearGradient(
                colors: [courseColor, courseColor.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .locked:
            return LinearGradient(
                colors: [
                    Color(.tertiarySystemBackground),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Background

private struct CampusMapBackground: View {
    var body: some View {
        ZStack {
            LinearGradient.pageBackground

            Circle()
                .fill(Color.accentColor.opacity(0.18))
                .frame(width: 270, height: 270)
                .blur(radius: 80)
                .offset(x: 150, y: -250)

            Circle()
                .fill(Color.pink.opacity(0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 80)
                .offset(x: -160, y: 320)
        }
    }
}

#Preview {
    let store = ContentStore()

    return Group {
        if let department = store.department {
            NavigationStack {
                LevelSelectView(department: department)
            }
        } else {
            Text("No content")
        }
    }
    .modelContainer(for: PlayerProgress.self, inMemory: true)
}
