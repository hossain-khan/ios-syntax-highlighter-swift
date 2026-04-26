import SwiftUI

/// A SwiftUI view that renders syntax-highlighted code from Shiki tokens.
///
/// Supports three token types via separate initializers:
/// - ``init(tokens:)-7k3hc`` for single-theme ``Token`` arrays
/// - ``init(tokens:)-1lbh8`` for dual-theme ``DualToken`` arrays (auto-switches on system appearance change)
/// - ``init(tokens:colorMapping:)`` for ``SemanticToken`` arrays with a custom color palette
///
/// Renders as monospaced text in a bidirectional scroll view with text selection enabled.
public struct CodeHighlightView: View {
    private let content: Content
    @Environment(\.colorScheme) private var colorScheme

    private enum Content {
        case single([[Token]])
        case dual([[DualToken]])
        case semantic([[SemanticToken]], [TokenType: Color])
    }

    /// Renders tokens from a single-theme highlight response.
    public init(tokens: [[Token]]) {
        self.content = .single(tokens)
    }

    /// Renders tokens from a dual-theme response. Automatically picks dark or light color based on the current `colorScheme`.
    public init(tokens: [[DualToken]]) {
        self.content = .dual(tokens)
    }

    /// Renders semantic tokens with a custom color mapping from ``TokenType`` to `Color`.
    public init(tokens: [[SemanticToken]], colorMapping: [TokenType: Color]) {
        self.content = .semantic(tokens, colorMapping)
    }

    public var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Text(attributedString)
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled)
                .padding()
        }
    }

    private var attributedString: AttributedString {
        switch content {
        case .single(let tokens):
            return buildAttributedString(from: tokens) { token in
                Color(hex: token.color) ?? .primary
            }
        case .dual(let tokens):
            return buildAttributedString(from: tokens) { token in
                let hex = colorScheme == .dark ? token.darkColor : token.lightColor
                return Color(hex: hex) ?? .primary
            }
        case .semantic(let tokens, let mapping):
            return buildAttributedString(from: tokens) { token in
                mapping[token.type] ?? .primary
            }
        }
    }

    private func buildAttributedString<T>(
        from lines: [[T]],
        color: (T) -> Color
    ) -> AttributedString where T: TokenTextProvider {
        var result = AttributedString()
        for (lineIndex, line) in lines.enumerated() {
            for token in line {
                var attributed = AttributedString(token.tokenText)
                attributed.foregroundColor = color(token)
                result.append(attributed)
            }
            if lineIndex < lines.count - 1 {
                result.append(AttributedString("\n"))
            }
        }
        return result
    }
}

/// Internal protocol for extracting display text from any token type.
protocol TokenTextProvider {
    var tokenText: String { get }
}

extension Token: TokenTextProvider {
    var tokenText: String { text }
}

extension DualToken: TokenTextProvider {
    var tokenText: String { text }
}

extension SemanticToken: TokenTextProvider {
    var tokenText: String { text }
}
