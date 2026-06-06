//
//  DictionaryView.swift
//  CampusQuest
//
//  Step 6 UI upgrade: turns the learned words list into a polished
//  collection album. Completed levels become sections, and every word
//  appears as a collectible study card.
//

import SwiftUI
import SwiftData

struct DictionaryView: View {
    @Environment(ContentStore.self) private var store
    @Query private var progressList: [PlayerProgress]
    private var progress: PlayerProgress? { progressList.first }

    private let ink = Color(red: 0.18, green: 0.20, blue: 0.42)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                headerCard
                    .padding(.horizontal)
                    .padding(.top, 12)

                if learnedLevels.isEmpty {
                    emptyState
                        .padding(.horizontal)
                        .padding(.top, 20)
                } else {
                    VStack(spacing: 18) {
                        ForEach(learnedLevels) { level in
                            LearnedLevelSection(level: level)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(DictionaryBackground().ignoresSafeArea())
        .navigationTitle("Dictionary")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
    }

    private var learnedLevels: [GameLevel] {
        guard let department = store.department, let progress else { return [] }
        return department.levels.filter { progress.isCompleted($0.title) }
    }

    private var learnedWordCount: Int {
        learnedLevels.reduce(0) { $0 + $1.words.count }
    }

    private var totalWordCount: Int {
        store.department?.levels.reduce(0) { $0 + $1.words.count } ?? 0
    }

    private var progressFraction: Double {
        guard totalWordCount > 0 else { return 0 }
        return Double(learnedWordCount) / Double(totalWordCount)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor,
                                    Color(red: 0.52, green: 0.42, blue: 0.96)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)

                    Image(systemName: "book.closed.fill")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Word Collection")
                        .font(.title3.bold())
                        .foregroundStyle(ink)

                    Text("Review the terms you unlocked by completing levels.")
                        .font(.caption)
                        .foregroundStyle(ink.opacity(0.58))
                        .lineLimit(2)
                }

                Spacer()
            }

            VStack(spacing: 6) {
                HStack {
                    Text("\(learnedWordCount) / \(totalWordCount) words learned")
                        .font(.caption.bold())
                        .foregroundStyle(ink.opacity(0.68))

                    Spacer()

                    Text("\(Int((progressFraction * 100).rounded()))%")
                        .font(.caption.bold())
                        .foregroundStyle(Color.accentColor)
                }

                ProgressView(value: progressFraction)
                    .tint(Color.accentColor)
            }
        }
        .padding()
        .background(Color.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.accentColor.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.80))
                    .frame(width: 110, height: 110)
                    .shadow(color: .black.opacity(0.06), radius: 10, y: 4)

                Image(systemName: "book.closed")
                    .font(.system(size: 54))
                    .foregroundStyle(Color.accentColor.opacity(0.75))
            }

            Text("No words yet")
                .font(.title2.bold())
                .foregroundStyle(ink)

            Text("Complete a level to unlock its words as collectible study cards.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(ink.opacity(0.58))
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .padding(.horizontal)
        .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 26))
    }
}

// MARK: - Learned level section

private struct LearnedLevelSection: View {
    let level: GameLevel

    @State private var selectedWord: WordItem?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon(for: level.title))
                    .font(.headline.bold())
                    .foregroundStyle(accent(for: level.title))
                    .frame(width: 34, height: 34)
                    .background(accent(for: level.title).opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.title)
                        .font(.headline)

                    Text("\(level.words.count) mastered words")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(level.words) { word in
                    Button {
                        selectedWord = word
                    } label: {
                        WordCollectionCard(
                            word: word,
                            accent: accent(for: level.title),
                            icon: wordIcon(for: word.category, fallback: icon(for: level.title))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        .sheet(item: $selectedWord) { word in
            WordDetailSheet(
                word: word,
                levelTitle: level.title,
                accent: accent(for: level.title),
                icon: wordIcon(for: word.category, fallback: icon(for: level.title))
            )
            .presentationDetents([.medium])
        }
    }

    private func accent(for title: String) -> Color {
        switch title {
        case "Programming Fundamentals":
            return Color(red: 0.16, green: 0.58, blue: 0.98)
        case "Data Structures":
            return Color(red: 0.42, green: 0.35, blue: 0.92)
        case "Computer Networks":
            return Color(red: 0.06, green: 0.68, blue: 0.64)
        case "Databases":
            return Color(red: 0.98, green: 0.56, blue: 0.18)
        case "Cybersecurity":
            return Color(red: 0.18, green: 0.76, blue: 0.34)
        default:
            return Color.accentColor
        }
    }

    private func icon(for title: String) -> String {
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

    private func wordIcon(for category: String, fallback: String) -> String {
        let lower = category.lowercased()

        if lower.contains("program") || lower.contains("code") {
            return "chevron.left.forwardslash.chevron.right"
        }

        if lower.contains("data structure") || lower.contains("structure") {
            return "square.stack.3d.up.fill"
        }

        if lower.contains("network") {
            return "network"
        }

        if lower.contains("database") || lower.contains("sql") {
            return "cylinder.split.1x2.fill"
        }

        if lower.contains("security") || lower.contains("cyber") {
            return "lock.shield.fill"
        }

        return fallback
    }
}

// MARK: - Word card

private struct WordCollectionCard: View {
    let word: WordItem
    let accent: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(accent.opacity(0.16))
                        .frame(width: 42, height: 42)

                    Image(systemName: icon)
                        .font(.headline.bold())
                        .foregroundStyle(accent)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(word.displayName)
                    .font(.headline.bold())
                    .foregroundStyle(Color(red: 0.18, green: 0.20, blue: 0.42))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(word.category)
                    .font(.caption2.bold())
                    .foregroundStyle(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Text(word.definition)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(minHeight: 170, alignment: .top)
        .background(
            LinearGradient(
                colors: [
                    Color.white,
                    accent.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(accent.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: accent.opacity(0.08), radius: 7, y: 3)
    }
}

// MARK: - Word detail sheet

private struct WordDetailSheet: View {
    let word: WordItem
    let levelTitle: String
    let accent: Color
    let icon: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.icon)
                            .fill(accent.opacity(0.16))
                            .frame(width: 60, height: 60)
                        Image(systemName: icon)
                            .font(.title2.bold())
                            .foregroundStyle(accent)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(word.displayName)
                            .font(.title2.bold())
                            .foregroundStyle(AppColor.ink)
                        Text(word.category)
                            .font(.caption.bold())
                            .foregroundStyle(accent)
                    }

                    Spacer()

                    Label("Mastered", systemImage: "checkmark.seal.fill")
                        .font(.caption2.bold())
                        .foregroundStyle(AppColor.success)
                }

                detailBlock(title: "Definition", icon: "text.book.closed", body: word.definition)

                detailBlock(title: "Used in", icon: "mappin.and.ellipse", body: levelTitle)

                Button { dismiss() } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: AppRadius.control))
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
    }

    private func detailBlock(title: String, icon: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(AppColor.inkSecondary)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: AppRadius.icon))
    }
}

// MARK: - Background

private struct DictionaryBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.84, green: 0.92, blue: 1.00),
                    Color(red: 0.95, green: 0.91, blue: 1.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.accentColor.opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(x: 150, y: -250)

            Circle()
                .fill(Color.pink.opacity(0.14))
                .frame(width: 240, height: 240)
                .blur(radius: 80)
                .offset(x: -150, y: 320)

            FloatingLetter("A", x: -130, y: -220, rotation: -12)
            FloatingLetter("Q", x: 130, y: -150, rotation: 10)
            FloatingLetter("C", x: -120, y: 260, rotation: 8)
        }
    }
}

private struct FloatingLetter: View {
    let letter: String
    let x: CGFloat
    let y: CGFloat
    let rotation: Double

    init(_ letter: String, x: CGFloat, y: CGFloat, rotation: Double) {
        self.letter = letter
        self.x = x
        self.y = y
        self.rotation = rotation
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.34))
            .overlay(
                Text(letter)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 0.30, green: 0.34, blue: 0.60).opacity(0.22))
            )
            .frame(width: 58, height: 58)
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: y)
    }
}

#Preview {
    NavigationStack {
        DictionaryView()
            .environment(ContentStore())
    }
    .modelContainer(for: PlayerProgress.self, inMemory: true)
}
