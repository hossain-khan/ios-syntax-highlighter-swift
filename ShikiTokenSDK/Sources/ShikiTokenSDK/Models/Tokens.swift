import Foundation

/// A single-theme syntax token: a code fragment with one color.
public struct Token: Codable, Hashable, Sendable {
    /// The code text fragment (e.g. `"fun"`, `" "`, `"main"`).
    public let text: String
    /// Hex color string (`#RRGGBB`) for this token, or empty if uncolored.
    public let color: String

    public init(text: String, color: String) {
        self.text = text
        self.color = color
    }
}

/// A dual-theme syntax token: a code fragment with both dark and light colors.
public struct DualToken: Codable, Hashable, Sendable {
    /// The code text fragment.
    public let text: String
    /// Hex color for dark mode.
    public let darkColor: String
    /// Hex color for light mode.
    public let lightColor: String

    public init(text: String, darkColor: String, lightColor: String) {
        self.text = text
        self.darkColor = darkColor
        self.lightColor = lightColor
    }
}

/// A semantic syntax token: a code fragment classified by type instead of color.
public struct SemanticToken: Codable, Hashable, Sendable {
    /// The code text fragment.
    public let text: String
    /// The semantic classification (e.g. `.keyword`, `.string`, `.variable`).
    public let type: TokenType

    public init(text: String, type: TokenType) {
        self.text = text
        self.type = type
    }
}
