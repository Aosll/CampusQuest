//
//  LevelView.swift
//  CampusQuest
//
//  Gameplay screen for one level: a 2D lab scene that builds up as
//  words are found, the hint, answer slots, the letter wheel, a
//  prominent definition card, and saved progress/XP on completion.
//

import SwiftUI
import SwiftData
import UIKit

struct LevelView: View {
    let level: GameLevel
    let totalLevels: Int

    @Environment(\.modelContext) private var modelContext

    @State private var model: LevelGameModel
    @State private var preview = ""
    @State private var wrongShake = 0
    @State private var showDefinition = false
    @State private var reward: LevelReward?
    @State private var didRecord = false
    @State private var showWordFound = false
    @State private var foundWordText = ""
    @State private var successPulse = false

    init(level: GameLevel, totalLevels: Int) {
        self.level = level
        self.totalLevels = totalLevels
        _model = State(initialValue: LevelGameModel(level: level))
    }

    var body: some View {
        Group {
            if model.isLevelComplete {
                levelCompleteView
            } else if let word = model.currentWord {
                gameView(for: word)
            }
        }
        .padding()
        .overlay(alignment: .top) {
            if showWordFound {
                WordFoundToast(word: foundWordText)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale))
                    .zIndex(10)
            }
        }
        .navigationTitle(level.title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: model.isLevelComplete) { _, complete in
            if complete && !didRecord {
                didRecord = true
                recordCompletion()
            }
        }
        .sheet(isPresented: $showDefinition) {
            if let word = model.lastFoundWord {
                DefinitionCard(word: word) {
                    showDefinition = false
                    model.advance()
                }
                .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Gameplay

    private func gameView(for word: WordItem) -> some View {
        VStack(spacing: 14) {
            LabSceneView(levelTitle: level.title,
                         totalWords: level.words.count,
                         foundCount: model.currentIndex)
                .scaleEffect(successPulse ? 1.025 : 1)

            VStack(spacing: 4) {
                Text("HINT")
                    .font(.caption2.bold())
                    .foregroundStyle(.tint)
                Text(word.definition)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal)

            answerSlots(for: word)
                .modifier(ShakeEffect(animatableData: CGFloat(wrongShake)))

            Spacer(minLength: 8)

            LetterWheelView(
                tiles: model.tiles,
                onPreview: { preview = $0 },
                onSubmit: handleGuess
            )
            .frame(height: 260)

            Spacer(minLength: 4)

            Button {
                model.shuffleTiles()
            } label: {
                Label("Shuffle", systemImage: "shuffle")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private func answerSlots(for word: WordItem) -> some View {
        let size = slotWidth(for: word.word.count)
        let chars = Array(preview)
        return HStack(spacing: 6) {
            ForEach(0..<word.word.count, id: \.self) { i in
                let filled = i < chars.count
                Text(filled ? String(chars[i]).uppercased() : "")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(filled ? .white : .clear)
                    .frame(width: size, height: size + 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(filled ? Color.accentColor : Color(.tertiarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(filled ? Color.accentColor
                                                 : Color.secondary.opacity(0.4),
                                          lineWidth: 1.5)
                    )
            }
        }
    }

    private func handleGuess(_ guess: String) {
        preview = ""
        if model.submit(guess: guess) {
            triggerSuccessFeedback(for: guess)
        } else if !guess.isEmpty {
            withAnimation(.default) { wrongShake += 1 }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private func triggerSuccessFeedback(for guess: String) {
        foundWordText = guess.uppercased()

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        withAnimation(.spring(response: 0.32, dampingFraction: 0.68)) {
            showWordFound = true
            successPulse = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                successPulse = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            withAnimation(.easeInOut(duration: 0.22)) {
                showWordFound = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            showDefinition = true
        }
    }

    private func slotWidth(for count: Int) -> CGFloat {
        let available: CGFloat = 320
        let spacing: CGFloat = 6
        let raw = (available - CGFloat(count - 1) * spacing) / CGFloat(count)
        return min(34, max(16, raw))
    }

    // MARK: - Progress

    private func recordCompletion() {
        let progress = PlayerProgress.current(in: modelContext)
        reward = progress.recordCompletion(levelTitle: level.title,
                                           wordCount: level.words.count,
                                           totalLevels: totalLevels)
    }

    // MARK: - Level complete

    private var levelCompleteView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.22), Color.accentColor.opacity(0.18)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 104, height: 104)

                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 62))
                            .foregroundStyle(.green)
                            .shadow(color: .green.opacity(0.30), radius: 12, y: 5)
                    }

                    Text("Level Complete!")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)

                    Text("You found all \(level.words.count) words in \(level.title).")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                .padding(.top, 10)

                RewardSummaryCard(
                    xpGained: reward?.xpGained,
                    newBadges: reward?.newBadges ?? [],
                    wordCount: level.words.count
                )

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Completed Lab", systemImage: "sparkles")
                            .font(.headline)
                        Spacer()
                        Text("100%")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }

                    LabSceneView(levelTitle: level.title,
                                 totalWords: level.words.count,
                                 foundCount: level.words.count)
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 22))

                LearnedWordsPreview(words: level.words)

                Text("Return to the campus map to continue your quest.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
            }
        }
    }
}

/// Prominent card shown after a word is found, with its meaning.
struct DefinitionCard: View {
    let word: WordItem
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 14) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.green)
                Text(word.displayName)
                    .font(.title.bold())
                Text(word.definition)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 12, y: 4)

            Button(action: onContinue) {
                Text("Got it")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.tint, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
        }
        .padding()
    }
}


private struct RewardSummaryCard: View {
    let xpGained: Int?
    let newBadges: [String]
    let wordCount: Int

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                RewardMetric(
                    icon: "star.fill",
                    title: xpGained != nil ? "+\(xpGained!) XP" : "Already Earned",
                    subtitle: xpGained != nil ? "Level reward" : "No duplicate XP",
                    color: Color.accentColor
                )

                RewardMetric(
                    icon: "textformat.abc",
                    title: "\(wordCount)",
                    subtitle: "Words found",
                    color: .green
                )
            }

            if !newBadges.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(newBadges.count > 1 ? "New badges unlocked" : "New badge unlocked")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(newBadges, id: \.self) { badge in
                        HStack(spacing: 8) {
                            Image(systemName: "rosette")
                                .foregroundStyle(Color.accentColor)
                            Text(badge)
                                .font(.subheadline.bold())
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .padding(10)
                        .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.white, Color.accentColor.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(Color.accentColor.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.accentColor.opacity(0.10), radius: 12, y: 5)
    }
}

private struct RewardMetric: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3.bold())
                .foregroundStyle(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.14), in: Circle())

            Text(title)
                .font(.headline.bold())
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct LearnedWordsPreview: View {
    let words: [WordItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Words Added to Dictionary", systemImage: "book.closed")
                    .font(.headline)
                Spacer()
                Text("\(words.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(words.prefix(4)) { word in
                    HStack(spacing: 10) {
                        Text(String(word.displayName.prefix(1)).uppercased())
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.accentColor, in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(word.displayName)
                                .font(.subheadline.bold())
                            Text(word.definition)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                }
            }

            if words.count > 4 {
                Text("+\(words.count - 4) more words saved in Dictionary")
                    .font(.caption.bold())
                    .foregroundStyle(.tint)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 2)
            }
        }
        .padding()
        .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}


/// A simple horizontal shake used to signal a wrong answer.
struct ShakeEffect: GeometryEffect {
    var travel: CGFloat = 8
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translationX = travel * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: translationX, y: 0))
    }
}

private struct WordFoundToast: View {
    let word: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.headline)

            VStack(alignment: .leading, spacing: 1) {
                Text("WORD FOUND!")
                    .font(.caption2.bold())
                    .opacity(0.82)
                Text(word)
                    .font(.headline.bold())
            }

            Text("+10 XP")
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.white.opacity(0.20), in: Capsule())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color.green, Color.accentColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: Capsule()
        )
        .shadow(color: Color.green.opacity(0.30), radius: 14, y: 6)
    }
}

#Preview {
    let store = ContentStore()
    return Group {
        if let level = store.department?.levels.first {
            NavigationStack {
                LevelView(level: level, totalLevels: 5)
            }
        } else {
            Text("No content")
        }
    }
    .modelContainer(for: PlayerProgress.self, inMemory: true)
}
