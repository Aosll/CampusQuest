//
//  QuizSessionModel.swift
//  CampusQuest
//
//  Runs a quiz session: a shuffled set of mixed-category questions,
//  the current question, the chosen answer, and the score.
//

import Foundation

@Observable
final class QuizSessionModel {
    let questions: [QuizQuestion]
    private(set) var index = 0
    private(set) var score = 0
    private(set) var selectedAnswer: String?
    private(set) var isFinished = false

    /// Picks up to `count` random questions from all available ones.
    init(allQuestions: [QuizQuestion], count: Int = 10) {
        questions = Array(allQuestions.shuffled().prefix(count))
        if questions.isEmpty { isFinished = true }
    }

    var currentQuestion: QuizQuestion? {
        guard index < questions.count else { return nil }
        return questions[index]
    }

    var progressText: String {
        "\(min(index + 1, questions.count)) / \(questions.count)"
    }

    /// True once the player has picked an answer for the current question.
    var hasAnswered: Bool { selectedAnswer != nil }

    /// Records the player's choice and updates the score.
    func choose(_ option: String) {
        guard selectedAnswer == nil, let question = currentQuestion else { return }
        selectedAnswer = option
        if question.isCorrect(option) { score += 1 }
    }

    /// Moves to the next question, or finishes the quiz.
    func next() {
        selectedAnswer = nil
        index += 1
        if index >= questions.count { isFinished = true }
    }
}
