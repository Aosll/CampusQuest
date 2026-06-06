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

struct LevelSelectView: View {
    let department: Department

    @Query private var progressList: [PlayerProgress]
    private var progress: PlayerProgress? { progressList.first }

    private let ink = Color(red: 0.18, green: 0.20, blue: 0.42)

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
                                LevelPathConnector(isActive: isUnlocked(index: index))
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
                                        icon: roomIcon(for: level.title),
                                        state: state,
                                        alignment: index.isMultiple(of: 2) ? .leading : .trailing
                                    )
                                }
                                .buttonStyle(.plain)
                            } else {
                                LevelRoomCard(
                                    number: index + 1,
                                    level: level,
                                    icon: roomIcon(for: level.title),
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
        .preferredColorScheme(.light)
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

    private func roomIcon(for title: String) -> String {
        switch title {
        case "Programming Fundamentals":
            return "terminal.fill"
        case "Data Structures":
            return "square.stack.3d.up.fill"
        case "Computer Networks":
            return "network"
        case "Databases":
            return "cylinder.split.1x2.fill"
        case "Cybersecurity":
            return "lock.shield.fill"
        default:
            return "graduationcap.fill"
        }
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
                .overlay {
                    HStack(spacing: 14) {
                        miniBuilding(icon: "curlybraces")
                        miniBuilding(icon: "server.rack")
                        miniBuilding(icon: "lock.shield")
                    }
                    .offset(y: 10)
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

private struct LevelPathConnector: View {
    let isActive: Bool

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { _ in
                Circle()
                    .fill(isActive ? Color.accentColor.opacity(0.55) : Color.secondary.opacity(0.22))
                    .frame(width: 7, height: 7)
            }
        }
        .frame(height: 36)
    }
}

private struct LevelRoomCard: View {
    let number: Int
    let level: GameLevel
    let icon: String
    let state: RoomState
    let alignment: HorizontalAlignment

    private let ink = Color(red: 0.18, green: 0.20, blue: 0.42)

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

                    Text(level.title)
                        .font(.headline)
                        .foregroundStyle(state == .locked ? ink.opacity(0.45) : ink)
                        .lineLimit(2)

                    Text("\(level.words.count) words")
                        .font(.caption)
                        .foregroundStyle(ink.opacity(0.55))
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
            .font(.caption2.bold())
            .padding(.horizontal, 8)
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
            return .green
        case .available:
            return Color.accentColor
        case .locked:
            return .secondary
        }
    }

    private var cardBackground: Color {
        switch state {
        case .completed, .available:
            return .white
        case .locked:
            return Color.white.opacity(0.72)
        }
    }

    private var borderColor: Color {
        switch state {
        case .completed:
            return .green.opacity(0.28)
        case .available:
            return Color.accentColor.opacity(0.42)
        case .locked:
            return .secondary.opacity(0.14)
        }
    }

    private var shadowColor: Color {
        switch state {
        case .completed:
            return .green.opacity(0.12)
        case .available:
            return Color.accentColor.opacity(0.18)
        case .locked:
            return .black.opacity(0.04)
        }
    }

    private var thumbnailGradient: LinearGradient {
        switch state {
        case .completed:
            return LinearGradient(
                colors: [.green, Color.accentColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .available:
            return LinearGradient(
                colors: [
                    Color.accentColor,
                    Color(red: 0.50, green: 0.42, blue: 0.96)
                ],
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
            LinearGradient(
                colors: [
                    Color(red: 0.82, green: 0.91, blue: 1.00),
                    Color(red: 0.94, green: 0.90, blue: 1.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

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
