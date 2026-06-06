//
//  QuizView.swift
//  CampusQuest
//
//  Step 7 UI upgrade: gamified quiz with card animations, combo counter,
//  correct/wrong feedback effects, and weak-topic analysis on results.
//

import SwiftUI

struct QuizView: View {
    @Environment(ContentStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var model: QuizSessionModel?
    @State private var cardShake: [String: Int] = [:]
    @State private var correctGlow: String? = nil
    @State private var combo = 0
    @State private var showCombo = false

    var body: some View {
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
        .padding()
        .navigationTitle("Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if model == nil {
                model = QuizSessionModel(allQuestions: store.quizQuestions)
            }
        }
    }

    // MARK: - Question

    private func questionView(_ model: QuizSessionModel, _ question: QuizQuestion) -> some View {
        VStack(spacing: 20) {
            // Progress + Combo
            VStack(spacing: 4) {
                HStack {
                    ProgressView(value: Double(model.index),
                                 total: Double(max(model.questions.count, 1)))

                    if combo >= 2 {
                        ComboChip(count: combo)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                Text(model.progressText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 8) {
                Text("Which subject does this term belong to?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text(question.word.displayName)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 12) {
                ForEach(question.options, id: \.self) { option in
                    Button {
                        handleAnswer(model: model, question: question, option: option)
                    } label: {
                        HStack {
                            Text(option)
                                .font(.headline)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if model.hasAnswered {
                                if option == question.correctAnswer {
                                    Image(systemName: "checkmark.circle.fill")
                                        .transition(.scale.combined(with: .opacity))
                                } else if option == model.selectedAnswer {
                                    Image(systemName: "xmark.circle.fill")
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            optionBackground(model, question, option),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .foregroundStyle(optionForeground(model, question, option))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(optionBorder(model, question, option), lineWidth: 1.5)
                        )
                        .shadow(
                            color: optionShadow(model, question, option),
                            radius: model.hasAnswered && option == question.correctAnswer ? 12 : 4,
                            y: 4
                        )
                    }
                    .disabled(model.hasAnswered)
                    .modifier(ShakeEffect(animatableData: CGFloat(cardShake[option] ?? 0)))
                    .scaleEffect(correctGlow == option ? 1.03 : 1.0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.65), value: correctGlow)
                    .animation(.spring(response: 0.35, dampingFraction: 0.65), value: model.hasAnswered)
                }
            }

            if model.hasAnswered {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        correctGlow = nil
                        model.next()
                    }
                } label: {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.tint, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: model.hasAnswered)
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: combo)
    }

    private func handleAnswer(model: QuizSessionModel, question: QuizQuestion, option: String) {
        model.choose(option)
        let isCorrect = (option == question.correctAnswer)

        if isCorrect {
            combo += 1
            correctGlow = option
            withAnimation(.spring(response: 0.28, dampingFraction: 0.60)) {
                showCombo = combo >= 2
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            combo = 0
            showCombo = false
            cardShake[option, default: 0] += 1
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private func optionBackground(_ model: QuizSessionModel, _ question: QuizQuestion, _ option: String) -> Color {
        guard model.hasAnswered else { return Color(.secondarySystemBackground) }
        if option == question.correctAnswer {
            return Color.green
        }
        if option == model.selectedAnswer {
            return Color.red.opacity(0.82)
        }
        return Color(.secondarySystemBackground)
    }

    private func optionForeground(_ model: QuizSessionModel, _ question: QuizQuestion, _ option: String) -> Color {
        guard model.hasAnswered else { return .primary }
        if option == question.correctAnswer || option == model.selectedAnswer { return .white }
        return .secondary
    }

    private func optionBorder(_ model: QuizSessionModel, _ question: QuizQuestion, _ option: String) -> Color {
        guard model.hasAnswered else { return Color.secondary.opacity(0.20) }
        if option == question.correctAnswer { return .green }
        if option == model.selectedAnswer { return .red }
        return Color.secondary.opacity(0.12)
    }

    private func optionShadow(_ model: QuizSessionModel, _ question: QuizQuestion, _ option: String) -> Color {
        guard model.hasAnswered else { return .black.opacity(0.04) }
        if option == question.correctAnswer { return .green.opacity(0.32) }
        if option == model.selectedAnswer { return .red.opacity(0.22) }
        return .black.opacity(0.04)
    }

    // MARK: - Result

    private func resultView(_ model: QuizSessionModel) -> some View {
        let pct = model.questions.isEmpty ? 0 : Int((Double(model.score) / Double(model.questions.count) * 100).rounded())
        let weakTopics = computeWeakTopics(model)
        let strongTopics = computeStrongTopics(model)

        return ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Score circle
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.12), lineWidth: 10)
                        .frame(width: 130, height: 130)
                    Circle()
                        .trim(from: 0, to: CGFloat(pct) / 100.0)
                        .stroke(
                            pct >= 70 ? Color.green : (pct >= 40 ? Color.accentColor : Color.red),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text("\(pct)%")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                        Text("score")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 12)

                Text("Quiz Complete!")
                    .font(.title.bold())

                Text("\(model.score) / \(model.questions.count) correct")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Topic analysis
                if !strongTopics.isEmpty || !weakTopics.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Performance Analysis")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if !strongTopics.isEmpty {
                            ForEach(strongTopics, id: \.self) { topic in
                                TopicAnalysisRow(
                                    icon: "checkmark.seal.fill",
                                    label: "Strong in \(topic)",
                                    color: .green
                                )
                            }
                        }
                        if !weakTopics.isEmpty {
                            ForEach(weakTopics, id: \.self) { topic in
                                TopicAnalysisRow(
                                    icon: "arrow.clockwise.circle.fill",
                                    label: "Review \(topic) again",
                                    color: .orange
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
                }

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.tint, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)
                .padding(.bottom, 12)
            }
        }
    }

    private func computeWeakTopics(_ model: QuizSessionModel) -> [String] {
        var wrong: [String: Int] = [:]
        var total: [String: Int] = [:]

        for (q, answered) in zip(model.questions, model.answers) {
            let cat = q.correctAnswer
            total[cat, default: 0] += 1
            if answered != q.correctAnswer {
                wrong[cat, default: 0] += 1
            }
        }

        return total.keys.filter { key in
            let w = wrong[key] ?? 0
            let t = total[key] ?? 1
            return Double(w) / Double(t) >= 0.5
        }.sorted()
    }

    private func computeStrongTopics(_ model: QuizSessionModel) -> [String] {
        var correct: [String: Int] = [:]
        var total: [String: Int] = [:]

        for (q, answered) in zip(model.questions, model.answers) {
            let cat = q.correctAnswer
            total[cat, default: 0] += 1
            if answered == q.correctAnswer {
                correct[cat, default: 0] += 1
            }
        }

        return total.keys.filter { key in
            let c = correct[key] ?? 0
            let t = total[key] ?? 1
            return t >= 2 && Double(c) / Double(t) >= 0.75
        }.sorted()
    }
}

// MARK: - Combo chip

private struct ComboChip: View {
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.caption.bold())
            Text("\(count)x COMBO")
                .font(.caption.bold())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            LinearGradient(
                colors: [Color.orange, Color.red],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: Capsule()
        )
        .shadow(color: .orange.opacity(0.35), radius: 8, y: 3)
    }
}

// MARK: - Topic analysis row

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
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        QuizView()
            .environment(ContentStore())
    }
}
