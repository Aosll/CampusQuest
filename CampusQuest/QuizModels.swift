//
//  QuizModels.swift
//  CampusQuest
//
//  Logic for the "which subject does this word belong to?" mini quiz.
//

import Foundation

/// A single multiple-choice quiz question.
struct QuizQuestion: Identifiable {
    let id = UUID()
    let word: WordItem
    let options: [String]      // 4 answer choices, already shuffled
    let correctAnswer: String  // equals word.category

    /// Returns true if the given choice is the correct category.
    func isCorrect(_ choice: String) -> Bool {
        choice == correctAnswer
    }
}

/// Builds quiz questions from a word and the list of possible categories.
enum QuizBuilder {
    /// Creates one question for a word: the correct category plus up to
    /// 3 random "distractor" categories, all shuffled together.
    static func makeQuestion(for word: WordItem, allCategories: [String]) -> QuizQuestion {
        let correct = word.category

        // Pick up to 3 wrong answers from the other categories.
        let distractors = allCategories
            .filter { $0 != correct }
            .shuffled()
            .prefix(3)

        var options = [correct] + distractors
        options.shuffle()

        return QuizQuestion(word: word, options: options, correctAnswer: correct)
    }
}

extension Department {
    /// All unique categories in this department, in the order they appear.
    /// Used to build quiz answer choices.
    var allCategories: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for level in levels {
            for word in level.words where seen.insert(word.category).inserted {
                result.append(word.category)
            }
        }
        return result
    }
}
