import Foundation

/// Request for single-theme syntax highlighting via `POST /highlight`.
public struct HighlightRequest: Encodable, Sendable {
    public let code: String
    public var language: String
    public var theme: String
    public var debug: Bool

    public init(
        code: String,
        language: String = ShikiLanguage.text,
        theme: String = ShikiTheme.githubDark,
        debug: Bool = false
    ) {
        self.code = code
        self.language = language
        self.theme = theme
        self.debug = debug
    }
}

/// Request for dual-theme (dark + light) highlighting via `POST /highlight/dual`.
public struct HighlightDualRequest: Encodable, Sendable {
    public let code: String
    public var language: String
    public var darkTheme: String
    public var lightTheme: String
    public var debug: Bool

    public init(
        code: String,
        language: String = ShikiLanguage.text,
        darkTheme: String = ShikiTheme.githubDark,
        lightTheme: String = ShikiTheme.githubLight,
        debug: Bool = false
    ) {
        self.code = code
        self.language = language
        self.darkTheme = darkTheme
        self.lightTheme = lightTheme
        self.debug = debug
    }
}

/// Request for semantic token-type highlighting via `POST /highlight/semantic`.
public struct HighlightSemanticRequest: Encodable, Sendable {
    public let code: String
    public var language: String
    public var debug: Bool

    public init(
        code: String,
        language: String = ShikiLanguage.text,
        debug: Bool = false
    ) {
        self.code = code
        self.language = language
        self.debug = debug
    }
}
