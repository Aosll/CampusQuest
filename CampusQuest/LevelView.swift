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

/// How a `LevelView` records its completion.
enum LevelMode {
    /// A normal course level: writes to `completedLevels` and grants level XP.
    case normal
    /// The playable Daily Challenge: grants a one-time daily bonus and never
    /// touches `completedLevels` or the regular level progression.
    case daily
}

struct LevelView: View {
    let level: GameLevel
    let totalLevels: Int
    var nextLevel: GameLevel? = nil
    var mode: LevelMode = .normal

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var progressList: [PlayerProgress]
    private var availableXP: Int { progressList.first?.totalXP ?? 0 }

    @State private var model: LevelGameModel
    @State private var preview = ""
    @State private var wrongShake = 0
    @State private var showDefinition = false
    @State private var reward: LevelReward?
    @State private var didRecord = false
    @State private var showWordFound = false
    @State private var foundWordText = ""
    @State private var successPulse = false
    @State private var slotFlash = false
    @State private var combo = 0
    @State private var revealedCount = 0
    @State private var particleTrigger = 0
    @State private var showParticles = false
    @State private var floatingXP = false
    @State private var completionPop = false

    /// XP cost to reveal one letter via the Hint button.
    private let hintCost = 5

    init(level: GameLevel, totalLevels: Int, nextLevel: GameLevel? = nil, mode: LevelMode = .normal) {
        self.level = level
        self.totalLevels = totalLevels
        self.nextLevel = nextLevel
        self.mode = mode
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
                // Ask for notification permission only after the player has
                // engaged (finished a level), never on first launch.
                Task { await NotificationManager.shared.requestAuthorizationIfNeeded() }
            }
        }
        .sheet(isPresented: $showDefinition) {
            if let word = model.lastFoundWord {
                DefinitionCard(
                    word: word,
                    foundCount: model.foundCount + 1,
                    totalWords: level.words.count
                ) {
                    showDefinition = false
                    model.advance()
                    revealedCount = 0
                    floatingXP = false
                }
                .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Gameplay

    private func gameView(for word: WordItem) -> some View {
        VStack(spacing: 14) {
            ZStack(alignment: .top) {
                LabSceneView(levelTitle: level.title,
                             totalWords: level.words.count,
                             foundCount: model.currentIndex)
                    .scaleEffect(successPulse ? 1.025 : 1)

                if combo >= 2 {
                    ComboBadge(count: combo)
                        .padding(.top, 6)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            VStack(spacing: 4) {
                Text("CLUE")
                    .font(.caption2.bold())
                    .foregroundStyle(.tint)
                Text(word.definition)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal)

            // Answer slots with success particles + floating XP overlay.
            ZStack {
                answerSlots(for: word)
                    .modifier(ShakeEffect(animatableData: CGFloat(wrongShake)))

                if showParticles {
                    ParticleBurst(color: CoursePalette.color(for: level.title))
                        .id(particleTrigger)
                        .allowsHitTesting(false)
                }

                if floatingXP {
                    Text("+10 XP")
                        .font(.headline.bold())
                        .foregroundStyle(AppColor.success)
                        .offset(y: floatingXP ? -54 : -10)
                        .opacity(floatingXP ? 0 : 1)
                        .allowsHitTesting(false)
                }
            }

            Spacer(minLength: 8)

            LetterWheelView(
                tiles: model.tiles,
                onPreview: { preview = $0 },
                onSubmit: handleGuess
            )
            .frame(height: 260)

            Spacer(minLength: 4)

            HStack(spacing: 12) {
                Button {
                    model.shuffleTiles()
                } label: {
                    Label("Shuffle", systemImage: "shuffle")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    useHint(for: word)
                } label: {
                    Label("Hint (\(hintCost) XP)", systemImage: "lightbulb.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(AppColor.warning)
                .disabled(!canUseHint(for: word))
            }
        }
    }

    private func canUseHint(for word: WordItem) -> Bool {
        revealedCount < word.word.count - 1 && availableXP >= hintCost
    }

    private func useHint(for word: WordItem) {
        guard canUseHint(for: word) else { return }
        guard PlayerProgress.current(in: modelContext).spendXP(hintCost) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            revealedCount += 1
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func answerSlots(for word: WordItem) -> some View {
        let size = slotWidth(for: word.word.count)
        let chars = Array(preview)
        let answer = Array(word.word)
        return HStack(spacing: 6) {
            ForEach(0..<word.word.count, id: \.self) { i in
                let filled = i < chars.count
                // A hinted (revealed) letter shows faintly until the player types it.
                let revealed = !filled && i < revealedCount
                let flashColor: Color = slotFlash ? .green : (filled ? Color.accentColor : Color(.tertiarySystemBackground))
                let borderColor: Color = slotFlash ? .green : (filled ? Color.accentColor : (revealed ? AppColor.warning.opacity(0.6) : Color.secondary.opacity(0.4)))
                Text(filled ? String(chars[i]).uppercased()
                            : (revealed ? String(answer[i]).uppercased() : ""))
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(filled ? .white : (revealed ? AppColor.warning.opacity(0.7) : .clear))
                    .frame(width: size, height: size + 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(flashColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(borderColor, lineWidth: 1.5)
                    )
                    .shadow(color: slotFlash ? .green.opacity(0.45) : .clear, radius: slotFlash ? 8 : 0)
                    .scaleEffect(slotFlash ? 1.08 : 1.0)
            }
        }
        .animation(.spring(response: 0.30, dampingFraction: 0.62), value: slotFlash)
    }

    private func handleGuess(_ guess: String) {
        preview = ""
        if model.submit(guess: guess) {
            PlayerProgress.current(in: modelContext).registerWordFound()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { combo += 1 }
            triggerSuccessFeedback(for: guess)
        } else if !guess.isEmpty {
            withAnimation(.default) { wrongShake += 1 }
            withAnimation { combo = 0 }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private func triggerSuccessFeedback(for guess: String) {
        foundWordText = guess.uppercased()

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // Particle burst + floating XP.
        particleTrigger += 1
        showParticles = true
        floatingXP = false
        withAnimation(.easeOut(duration: 0.9)) { floatingXP = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { showParticles = false }

        withAnimation(.spring(response: 0.32, dampingFraction: 0.68)) {
            showWordFound = true
            successPulse = true
            slotFlash = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                successPulse = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                slotFlash = false
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

    /// Stars for the run: 3 for a clean run, 2 for a few slips, else 1.
    private var starsEarned: Int {
        switch model.mistakeCount {
        case 0:    return 3
        case 1...2: return 2
        default:   return 1
        }
    }

    // MARK: - Progress

    private func recordCompletion() {
        let progress = PlayerProgress.current(in: modelContext)
        switch mode {
        case .normal:
            reward = progress.recordCompletion(levelTitle: level.title,
                                               wordCount: level.words.count,
                                               totalLevels: totalLevels,
                                               perfect: model.mistakeCount == 0)
        case .daily:
            // Separate bonus path: never affects `completedLevels`.
            reward = progress.recordDailyChallengeGame(bonusXP: DailyChallengeGame.bonusXP)
        }
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
                    .scaleEffect(completionPop ? 1 : 0.5)
                    .opacity(completionPop ? 1 : 0)

                    // Stars earned based on how clean the run was.
                    HStack(spacing: 10) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < starsEarned ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle(i < starsEarned ? AppColor.warning : Color.secondary.opacity(0.35))
                                .scaleEffect(completionPop ? 1 : 0.3)
                                .animation(.spring(response: 0.4, dampingFraction: 0.5)
                                    .delay(0.15 + Double(i) * 0.12), value: completionPop)
                        }
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
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                        completionPop = true
                    }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }

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

                // Action buttons
                VStack(spacing: 10) {
                    if let next = nextLevel {
                        NavigationLink {
                            LevelView(level: next, totalLevels: totalLevels)
                        } label: {
                            Label("Next Level", systemImage: "arrow.right.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: AppRadius.control))
                                .foregroundStyle(.white)
                                .shadow(color: AppColor.primary.opacity(0.35), radius: 10, y: 5)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }

                    HStack(spacing: 10) {
                        Button {
                            model = LevelGameModel(level: level)
                            didRecord = false
                            reward = nil
                            completionPop = false
                        } label: {
                            Label("Replay", systemImage: "arrow.clockwise")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: AppRadius.control))
                                .foregroundStyle(.primary)
                        }
                        .buttonStyle(PressableButtonStyle())

                        ShareLink(
                            item: "I just completed \(level.title) on Campus Quest! 🎓 Found all \(level.words.count) words. #CampusQuest"
                        ) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.primary)
                        }
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Back to Map")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 8)
                }
            }
        }
    }
}

/// Prominent card shown after a word is found, with its meaning plus a
/// reward header and progress so finding a word feels rewarding.
struct DefinitionCard: View {
    let word: WordItem
    var foundCount: Int = 1
    var totalWords: Int = 1
    let onContinue: () -> Void

    private var remaining: Int { max(totalWords - foundCount, 0) }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                // Reward header
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                    Text("Correct!")
                        .font(.title2.bold())
                    Text("+10 XP")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.25), in: Capsule())
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: [AppColor.success, AppColor.primary],
                                   startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: AppRadius.icon)
                )

                Text(word.displayName)
                    .font(.title.bold())
                    .foregroundStyle(AppColor.ink)
                Text(word.definition)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColor.inkSecondary)

                // Progress row
                VStack(spacing: 6) {
                    HStack {
                        Label("Progress \(foundCount)/\(totalWords) words", systemImage: "checklist")
                            .font(.caption.bold())
                            .foregroundStyle(AppColor.ink)
                        Spacer()
                        Text(remaining > 0 ? "\(remaining) to go" : "Level cleared!")
                            .font(.caption.bold())
                            .foregroundStyle(AppColor.secondary)
                    }
                    ProgressView(value: Double(foundCount), total: Double(max(totalWords, 1)))
                        .tint(AppColor.success)
                }
                .padding(.top, 4)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .strokeBorder(AppColor.success.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 12, y: 4)

            Button(action: onContinue) {
                Text(remaining > 0 ? "Next Word" : "Finish Level")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: AppRadius.control))
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

    @State private var badgePop = false

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
                    Label(newBadges.count > 1 ? "New achievements unlocked" : "New achievement unlocked",
                          systemImage: "sparkles")
                        .font(.caption.bold())
                        .foregroundStyle(AppColor.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(Array(newBadges.enumerated()), id: \.element) { index, badge in
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
                        .scaleEffect(badgePop ? 1 : 0.7)
                        .opacity(badgePop ? 1 : 0)
                        .animation(.spring(response: 0.45, dampingFraction: 0.55)
                            .delay(0.2 + Double(index) * 0.12), value: badgePop)
                    }
                }
                .onAppear {
                    badgePop = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
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

/// A small combo indicator shown for consecutive correct words.
private struct ComboBadge: View {
    let count: Int

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill")
            Text("Combo x\(count)")
        }
        .font(.caption.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing),
            in: Capsule()
        )
        .shadow(color: .orange.opacity(0.4), radius: 8, y: 3)
    }
}

/// A short particle burst played when a word is solved. Recreate it with a
/// changing `.id(...)` to replay the animation.
private struct ParticleBurst: View {
    let color: Color
    private let count = 12
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let angle = Double(i) / Double(count) * 2 * .pi
                Circle()
                    .fill(i.isMultiple(of: 2) ? color : AppColor.warning)
                    .frame(width: 8, height: 8)
                    .offset(x: animate ? cos(angle) * 80 : 0,
                            y: animate ? sin(angle) * 50 : 0)
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 0.2 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { animate = true }
        }
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
