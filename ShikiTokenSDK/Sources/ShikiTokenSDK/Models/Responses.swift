import Foundation

/// Response from `POST /highlight`. Contains single-theme colored tokens.
public struct HighlightResponse: Decodable, Sendable {
    public let language: String
    public let theme: String
    /// Lines of tokens. Outer array = lines, inner array = tokens within that line.
    public let tokens: [[Token]]
    /// Server performance metadata. Only present when `debug: true` was set in the request.
    public let debug: DebugInfo?

    private enum CodingKeys: String, CodingKey {
        case language, theme, tokens
        case debug = "_debug"
    }
}

/// Response from `POST /highlight/dual`. Contains tokens with both dark and light colors.
public struct HighlightDualResponse: Decodable, Sendable {
    public let language: String
    public let darkTheme: String
    public let lightTheme: String
    public let tokens: [[DualToken]]
    public let debug: DebugInfo?

    private enum CodingKeys: String, CodingKey {
        case language, darkTheme, lightTheme, tokens
        case debug = "_debug"
    }
}

/// Response from `POST /highlight/semantic`. Contains tokens classified by type, not color.
public struct HighlightSemanticResponse: Decodable, Sendable {
    public let language: String
    public let tokenTypes: [String]
    public let tokens: [[SemanticToken]]
    public let debug: DebugInfo?

    private enum CodingKeys: String, CodingKey {
        case language, tokenTypes, tokens
        case debug = "_debug"
    }
}

/// Response from `GET /languages`. Lists all supported languages and themes.
public struct LanguagesResponse: Decodable, Sendable {
    public let languages: [String]
    public let themes: [String]
}

/// Response from `GET /health`. Indicates service status and version.
public struct HealthResponse: Decodable, Sendable {
    public let status: String
    public let version: String
}

/// Error response body returned by the Shiki Token Service on 4xx/5xx status codes.
public struct ErrorResponse: Decodable, Sendable {
    public let error: String
    public let details: String?
}
