//
//  QuizView.swift
//  CampusQuest
//
//  "Soft Campus Quiz" — a gamified term-classification challenge styled to
//  match the home and level screens: gradient background, a glass question
//  card, a highlighted term chip, A/B/C/D answer cards with subject icons,
//  a hint, XP/streak chips, and a rewarding correct/wrong feedback card.
//

import SwiftUI
import SwiftData
import Combine

struct QuizView: View {
    @Environment(ContentStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var progressList: [PlayerProgress]

    @State private var model: QuizSessionModel?
    @State private var cardShake: [String: Int] = [:]
    @State private var correctGlow: String? = nil
    @State private var combo = 0
    @State private var showHint = false
    @State private var sessionXP = 0
    @State private var didPersist = false
    @State private var timeRemaining = 0
    @State private var xpFloat = false

    /// Ticks once per second to drive the per-question countdown.
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var baseXP: Int { progressList.first?.totalXP ?? 0 }

    /// Difficulty derived from the term's length (heuristic): label, seconds, color.
    private func difficulty(for question: QuizQuestion) -> (label: String, time: Int, color: Color) {
        switch question.word.word.count {
        case ...5:  return ("Easy", 20, AppColor.success)
        case 6...8: return ("Medium", 15, AppColor.warning)
        default:    return ("Hard", 12, Color(red: 0.90, green: 0.27, blue: 0.31))
        }
    }

    var body: some View {
        ZStack {
            QuizBackground().ignoresSafeArea()

            Group {
                if let model {
                    if model.isFinished {
                        resultView(model)
                    } else if let question = model.currentQuestion {
                        questionView(model, question)
                    }
                } else {
                    ProgressView()
                }
            }
        }
        .navigationTitle("Quiz Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
        .onAppear { buildModelIfNeeded() }
        // Content loads asynchronously; build the quiz once it's available.
        .onChange(of: store.department?.id) { _, _ in buildModelIfNeeded() }
        .onReceive(ticker) { _ in tick() }
        .onChange(of: model?.index) { _, _ in resetTimer() }
    }

    // MARK: - Question

    private func questionView(_ model: QuizSessionModel, _ question: QuizQuestion) -> some View {
        VStack(spacing: 16) {
            topBar(model)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    questionCard(model, question)

                    answerList(model, question)

                    if model.hasAnswered {
                        feedbackSection(model, question)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: model.hasAnswered)
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: showHint)
    }

    // MARK: Top bar (progress + XP/streak)

    private func topBar(_ model: QuizSessionModel) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text("Question \(min(model.index + 1, model.questions.count)) of \(model.questions.count)")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColor.ink)

                Spacer()

                HStack(spacing: 8) {
                    if combo >= 2 {
                        StatChip(icon: "flame.fill", text: "\(combo)", tint: AppColor.warning)
                            .transition(.scale.combined(with: .opacity))
                    }
                    StatChip(icon: "star.fill", text: "\(baseXP + sessionXP)", tint: AppColor.secondary)
                        .scaleEffect(xpFloat ? 1.12 : 1)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: xpFloat)
                        .overlay(alignment: .top) {
                            // +10 XP floats up toward the counter on a correct answer.
                            if xpFloat {
                                Text("+10")
                                    .font(.caption.bold())
                                    .foregroundStyle(AppColor.success)
                                    .offset(y: xpFloat ? -22 : 6)
                                    .opacity(xpFloat ? 0 : 1)
                            }
                        }
                }
            }

            // Thicker, rounded blue progress bar.
            GeometryReader { geo in
                let fraction = model.questions.isEmpty
                    ? 0
                    : Double(model.index) / Double(model.questions.count)
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColor.locked.opacity(0.25))
                    Capsule()
                        .fill(LinearGradient.brand)
                        .frame(width: max(8, geo.size.width * fraction))
                }
            }
            .frame(height: 10)

            Text("+10 XP per correct answer")
                .font(.caption2.bold())
                .foregroundStyle(AppColor.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: combo)
    }

    // MARK: Question card

    private func questionCard(_ model: QuizSessionModel, _ question: QuizQuestion) -> some View {
        GlassCard(cornerRadius: AppRadius.largeCard) {
            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "text.magnifyingglass")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColor.primary)
                    Text("Classify the Term")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColor.ink)
                    Spacer()

                    let diff = difficulty(for: question)
                    // Difficulty indicator.
                    Text(diff.label)
                        .font(.caption2.bold())
                        .foregroundStyle(diff.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(diff.color.opacity(0.14), in: Capsule())

                    // Countdown timer.
                    HStack(spacing: 3) {
                        Image(systemName: "timer")
                        Text("\(timeRemaining)s")
                    }
                    .font(.caption2.bold())
                    .foregroundStyle(timeRemaining <= 5 && !model.hasAnswered ? Color.red : AppColor.inkSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (timeRemaining <= 5 && !model.hasAnswered ? Color.red : AppColor.inkSecondary).opacity(0.12),
                        in: Capsule()
                    )
                }

                Text("Which course does this word belong to?")
                    .font(.callout)
                    .foregroundStyle(AppColor.inkSecondary)
                    .multilineTextAlignment(.center)

                // Highlighted term chip.
                VStack(spacing: 4) {
                    Text(question.word.displayName)
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppColor.ink)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [AppColor.primary.opacity(0.18), AppColor.secondary.opacity(0.18)],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                        )
                        .overlay(Capsule().strokeBorder(AppColor.primary.opacity(0.25), lineWidth: 1))
                        .shadow(color: AppColor.primary.opacity(0.18), radius: 10, y: 4)

                    Text("Term to classify")
                        .font(.caption2)
                        .foregroundStyle(AppColor.inkSecondary)
                }

                // Hint.
                if showHint {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(AppColor.warning)
                        Text(question.word.definition)
                            .font(.caption)
                            .foregroundStyle(AppColor.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColor.warning.opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.icon))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else if !model.hasAnswered {
                    Button {
                        withAnimation { showHint = true }
                    } label: {
                        Label("Hint", systemImage: "lightbulb")
                            .font(.caption.bold())
                            .foregroundStyle(AppColor.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(AppColor.primary.opacity(0.10), in: Capsule())
                    }
                }
            }
            .padding(18)
        }
    }

    // MARK: Answer cards

    private func answerList(_ model: QuizSessionModel, _ question: QuizQuestion) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(question.options.enumerated()), id: \.element) { idx, option in
                Button {
                    handleAnswer(model: model, question: question, option: option)
                } label: {
                    AnswerCard(
                        letter: String(UnicodeScalar(65 + idx)!),  // A, B, C, D
                        title: option,
                        icon: categoryIcon(option),
                        state: cardState(model, question, option)
                    )
                }
                .disabled(model.hasAnswered)
                .buttonStyle(.plain)
                .modifier(ShakeEffect(animatableData: CGFloat(cardShake[option] ?? 0)))
                .scaleEffect(correctGlow == option ? 1.03 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.65), value: correctGlow)
                .animation(.spring(response: 0.35, dampingFraction: 0.65), value: model.hasAnswered)
            }
        }
    }

    private func cardState(_ model: QuizSessionModel, _ question: QuizQuestion, _ option: String) -> AnswerCard.State {
        guard model.hasAnswered else { return .normal }
        if option == question.correctAnswer { return .correct }
        if option == model.selectedAnswer { return .wrong }
        return .dimmed
    }

    // MARK: Feedback

    private func feedbackSection(_ model: QuizSessionModel, _ question: QuizQuestion) -> some View {
        let isCorrect = model.selectedAnswer == question.correctAnswer
        return VStack(spacing: 12) {
            AnswerFeedbackCard(
                isCorrect: isCorrect,
                word: question.word.displayName,
                correctAnswer: question.correctAnswer,
                explanation: question.word.definition
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    correctGlow = nil
                    showHint = false
                    model.next()
                }
            } label: {
                Text(model.index + 1 >= model.questions.count ? "See Results" : "Next Question")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: AppRadius.control))
                    .foregroundStyle(.white)
            }
            .buttonStyle(PressableButtonStyle())
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func handleAnswer(model: QuizSessionModel, question: QuizQuestion, option: String) {
        model.choose(option)
        let isCorrect = (option == question.correctAnswer)

        if isCorrect {
            combo += 1
            sessionXP += 10
            correctGlow = option
            // Float +10 XP toward the counter.
            xpFloat = false
            withAnimation(.easeOut(duration: 0.9)) { xpFloat = true }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            combo = 0
            cardShake[option, default: 0] += 1
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    /// Builds the quiz session once content is available (guards against the
    /// content still loading when the screen first appears).
    private func buildModelIfNeeded() {
        guard model == nil, let department = store.department else { return }
        let questions = department.levels.flatMap { store.questions(for: $0) }
        guard !questions.isEmpty else { return }
        model = QuizSessionModel(allQuestions: questions)
        resetTimer()
    }

    // MARK: - Timer

    private func resetTimer() {
        guard let model, let q = model.currentQuestion, !model.isFinished else { return }
        timeRemaining = difficulty(for: q).time
        xpFloat = false
    }

    private func tick() {
        guard let model, !model.isFinished, !model.hasAnswered else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            timeOut(model: model)
        }
    }

    /// Time ran out: record a non-matching answer so it counts as wrong and
    /// the correct option is revealed.
    private func timeOut(model: QuizSessionModel) {
        guard !model.hasAnswered else { return }
        combo = 0
        model.choose("__timeout__")
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    // MARK: - Result

    private func resultView(_ model: QuizSessionModel) -> some View {
        let pct = model.questions.isEmpty ? 0 : Int((Double(model.score) / Double(model.questions.count) * 100).rounded())
        let weakTopics = computeWeakTopics(model)
        let strongTopics = computeStrongTopics(model)

        return ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(AppColor.locked.opacity(0.18), lineWidth: 10)
                        .frame(width: 130, height: 130)
                    Circle()
                        .trim(from: 0, to: CGFloat(pct) / 100.0)
                        .stroke(
                            pct >= 70 ? AppColor.success : (pct >= 40 ? AppColor.primary : Color.red),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text("\(pct)%")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppColor.ink)
                        Text("score")
                            .font(.caption)
                            .foregroundStyle(AppColor.inkSecondary)
                    }
                }
                .padding(.top, 12)

                Text("Quiz Complete!")
                    .font(.title.bold())
                    .foregroundStyle(AppColor.ink)

                HStack(spacing: 10) {
                    StatChip(icon: "checkmark.circle.fill", text: "\(model.score)/\(model.questions.count) correct", tint: AppColor.success)
                    StatChip(icon: "star.fill", text: "+\(sessionXP) XP", tint: AppColor.secondary)
                }

                // Rank progress after the freshly earned XP.
                let rank = RankSystem.progress(forXP: baseXP)
                VStack(spacing: 6) {
                    HStack {
                        Label(rank.title, systemImage: "graduationcap.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColor.ink)
                        Spacer()
                        Text(rank.nextTitle != nil ? "\(rank.percent)% to \(rank.nextTitle!)" : "Max rank")
                            .font(.caption.bold())
                            .foregroundStyle(AppColor.inkSecondary)
                    }
                    ProgressView(value: rank.fraction)
                        .tint(AppColor.primary)
                }
                .padding()
                .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: AppRadius.card))

                if !strongTopics.isEmpty || !weakTopics.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Performance Analysis")
                            .font(.headline)
                            .foregroundStyle(AppColor.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(strongTopics, id: \.self) { topic in
                            TopicAnalysisRow(icon: "checkmark.seal.fill", label: "Strong in \(topic)", color: AppColor.success)
                        }
                        ForEach(weakTopics, id: \.self) { topic in
                            TopicAnalysisRow(icon: "arrow.clockwise.circle.fill", label: "Review \(topic) again", color: AppColor.warning)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: AppRadius.card))
                }

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: AppRadius.control))
                        .foregroundStyle(.white)
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.top, 4)
                .padding(.bottom, 12)
            }
            .padding(.horizontal)
        }
        .onAppear {
            guard !didPersist else { return }
            didPersist = true
            PlayerProgress.current(in: modelContext).recordQuizFinished(correctCount: model.score)
        }
    }

    private func computeWeakTopics(_ model: QuizSessionModel) -> [String] {
        var wrong: [String: Int] = [:]
        var total: [String: Int] = [:]
        for (q, answered) in zip(model.questions, model.answers) {
            let cat = q.correctAnswer
            total[cat, default: 0] += 1
            if answered != q.correctAnswer { wrong[cat, default: 0] += 1 }
        }
        return total.keys.filter { key in
            Double(wrong[key] ?? 0) / Double(total[key] ?? 1) >= 0.5
        }.sorted()
    }

    private func computeStrongTopics(_ model: QuizSessionModel) -> [String] {
        var correct: [String: Int] = [:]
        var total: [String: Int] = [:]
        for (q, answered) in zip(model.questions, model.answers) {
            let cat = q.correctAnswer
            total[cat, default: 0] += 1
            if answered == q.correctAnswer { correct[cat, default: 0] += 1 }
        }
        return total.keys.filter { key in
            let t = total[key] ?? 1
            return t >= 2 && Double(correct[key] ?? 0) / Double(t) >= 0.75
        }.sorted()
    }
}

// MARK: - Category icons

/// Maps a course/category name to an SF Symbol for the answer cards.
func categoryIcon(_ category: String) -> String {
    let lower = category.lowercased()
    if lower.contains("network") { return "network" }
    if lower.contains("security") || lower.contains("cyber") { return "lock.shield" }
    if lower.contains("structure") { return "square.stack.3d.up" }
    if lower.contains("database") || lower.contains("sql") { return "server.rack" }
    if lower.contains("program") || lower.contains("code") { return "chevron.left.forwardslash.chevron.right" }
    return "graduationcap.fill"
}

// MARK: - Answer card

private struct AnswerCard: View {
    enum State { case normal, correct, wrong, dimmed }

    let letter: String
    let title: String
    let icon: String
    let state: State

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(badgeFill)
                Text(letter)
                    .font(.subheadline.bold())
                    .foregroundStyle(badgeText)
            }
            .frame(width: 32, height: 32)

            Text(title)
                .font(.headline)
                .foregroundStyle(AppColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            Image(systemName: trailingIcon)
                .font(.headline)
                .foregroundStyle(accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card)
                .strokeBorder(border, lineWidth: 1.5)
        )
        .shadow(color: shadow, radius: state == .correct ? 12 : 5, y: 3)
        .opacity(state == .dimmed ? 0.6 : 1)
    }

    private var trailingIcon: String {
        switch state {
        case .correct: return "checkmark.circle.fill"
        case .wrong: return "xmark.circle.fill"
        default: return icon
        }
    }

    private var accent: Color {
        switch state {
        case .correct: return AppColor.success
        case .wrong: return Color.red
        default: return AppColor.primary
        }
    }

    private var background: Color {
        switch state {
        case .normal, .dimmed: return Color.white.opacity(0.92)
        case .correct: return AppColor.success.opacity(0.16)
        case .wrong: return Color.red.opacity(0.12)
        }
    }

    private var border: Color {
        switch state {
        case .normal, .dimmed: return AppColor.locked.opacity(0.22)
        case .correct: return AppColor.success
        case .wrong: return Color.red.opacity(0.8)
        }
    }

    private var shadow: Color {
        switch state {
        case .correct: return AppColor.success.opacity(0.28)
        case .wrong: return Color.red.opacity(0.18)
        default: return .black.opacity(0.05)
        }
    }

    private var badgeFill: Color {
        switch state {
        case .correct: return AppColor.success
        case .wrong: return Color.red
        default: return AppColor.primary.opacity(0.14)
        }
    }

    private var badgeText: Color {
        switch state {
        case .correct, .wrong: return .white
        default: return AppColor.primary
        }
    }
}

// MARK: - Answer feedback

private struct AnswerFeedbackCard: View {
    let isCorrect: Bool
    let word: String
    let correctAnswer: String
    let explanation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.seal.fill" : "lightbulb.fill")
                    .foregroundStyle(isCorrect ? AppColor.success : AppColor.warning)
                Text(isCorrect ? "Correct!" : "Not quite")
                    .font(.headline)
                    .foregroundStyle(AppColor.ink)
                Spacer()
                if isCorrect {
                    Text("+10 XP")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppColor.success, in: Capsule())
                }
            }

            Text(isCorrect
                 ? "\(word) belongs to \(correctAnswer)."
                 : "Correct answer: \(correctAnswer)")
                .font(.subheadline.bold())
                .foregroundStyle(AppColor.ink)

            Text(explanation)
                .font(.caption)
                .foregroundStyle(AppColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (isCorrect ? AppColor.success : AppColor.warning).opacity(0.12),
            in: RoundedRectangle(cornerRadius: AppRadius.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card)
                .strokeBorder((isCorrect ? AppColor.success : AppColor.warning).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Small chips

private struct StatChip: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2.bold())
            Text(text)
                .font(.caption.bold())
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(tint.opacity(0.14), in: Capsule())
    }
}

private struct TopicAnalysisRow: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppColor.ink)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Background

private struct QuizBackground: View {
    var body: some View {
        ZStack {
            LinearGradient.pageBackground

            Circle()
                .fill(AppColor.primary.opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(x: 150, y: -260)
            Circle()
                .fill(AppColor.secondary.opacity(0.14))
                .frame(width: 240, height: 240)
                .blur(radius: 80)
                .offset(x: -150, y: 320)

            // Faint code symbols reinforcing the tech-campus identity.
            faintSymbol("{ }", x: -130, y: -250, size: 40, rotation: -10)
            faintSymbol("</>", x: 140, y: -180, size: 34, rotation: 8)
            faintSymbol("01", x: -140, y: 300, size: 38, rotation: 6)
            faintSymbol("#", x: 130, y: 340, size: 44, rotation: -8)
        }
    }

    private func faintSymbol(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat, rotation: Double) -> some View {
        Text(text)
            .font(.system(size: size, weight: .heavy, design: .monospaced))
            .foregroundStyle(AppColor.primary.opacity(0.06))
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: y)
    }
}

#Preview {
    NavigationStack {
        QuizView()
            .environment(ContentStore())
    }
    .modelContainer(for: PlayerProgress.self, inMemory: true)
}
