//
//  QuizView.swift
//  CampusQuest
//
//  A mixed-category quiz: "Which subject does this term belong to?"
//  Shows one question at a time with 4 options and a final score.
//

import SwiftUI

struct QuizView: View {
    @Environment(ContentStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var model: QuizSessionModel?

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
            ProgressView(value: Double(model.index),
                         total: Double(max(model.questions.count, 1)))
            Text(model.progressText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            VStack(spacing: 8) {
                Text("Which subject does this term belong to?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text(question.word.displayName)
                    .font(.largeTitle.bold())
            }

            Spacer()

            VStack(spacing: 12) {
                ForEach(question.options, id: \.self) { option in
                    Button {
                        model.choose(option)
                    } label: {
                        HStack {
                            Text(option)
                            Spacer()
                            if model.hasAnswered {
                                if option == question.correctAnswer {
                                    Image(systemName: "checkmark.circle.fill")
                                } else if option == model.selectedAnswer {
                                    Image(systemName: "xmark.circle.fill")
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(optionColor(model, question, option),
                                    in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(optionForeground(model, question, option))
                    }
                    .disabled(model.hasAnswered)
                }
            }

            if model.hasAnswered {
                Button {
                    model.next()
                } label: {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.tint, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private func optionColor(_ model: QuizSessionModel,
                             _ question: QuizQuestion,
                             _ option: String) -> Color {
        guard model.hasAnswered else { return Color(.secondarySystemBackground) }
        if option == question.correctAnswer { return .green }
        if option == model.selectedAnswer { return .red }
        return Color(.secondarySystemBackground)
    }

    private func optionForeground(_ model: QuizSessionModel,
                                  _ question: QuizQuestion,
                                  _ option: String) -> Color {
        guard model.hasAnswered else { return .primary }
        if option == question.correctAnswer || option == model.selectedAnswer { return .white }
        return .secondary
    }

    // MARK: - Result

    private func resultView(_ model: QuizSessionModel) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "rosette")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Quiz Complete!")
                .font(.title.bold())
            Text("You scored \(model.score) / \(model.questions.count)")
                .font(.title3)
                .foregroundStyle(.secondary)

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
            .padding(.top)
        }
    }
}

#Preview {
    NavigationStack {
        QuizView()
            .environment(ContentStore())
    }
}
