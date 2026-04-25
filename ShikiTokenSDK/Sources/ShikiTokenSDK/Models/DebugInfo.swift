import Foundation

/// Server-side performance metadata, returned when `debug: true` is set in the request.
public struct DebugInfo: Codable, Sendable {
    /// Total server processing time in milliseconds.
    public let totalMs: Double
    /// Time spent in the tokenizer, if available.
    public let tokenizerMs: Double?
    /// Size of the request body in bytes.
    public let requestBodyBytes: Int
    public let language: String?
    public let theme: String?
    public let darkTheme: String?
    public let lightTheme: String?

    public init(
        totalMs: Double,
        tokenizerMs: Double? = nil,
        requestBodyBytes: Int,
        language: String? = nil,
        theme: String? = nil,
        darkTheme: String? = nil,
        lightTheme: String? = nil
    ) {
        self.totalMs = totalMs
        self.tokenizerMs = tokenizerMs
        self.requestBodyBytes = requestBodyBytes
        self.language = language
        self.theme = theme
        self.darkTheme = darkTheme
        self.lightTheme = lightTheme
    }
}
