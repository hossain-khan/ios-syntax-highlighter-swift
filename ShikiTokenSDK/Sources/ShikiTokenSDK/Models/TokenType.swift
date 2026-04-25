import Foundation

/// Semantic classification of a code token, as identified by Shiki's TextMate grammar engine.
public enum TokenType: String, Codable, CaseIterable, Sendable {
    case keyword
    case type
    case modifier
    case function
    case tag
    case attribute
    case parameter
    case variable
    case number
    case constant
    case string
    case comment
    case punctuation
    case plain
}
