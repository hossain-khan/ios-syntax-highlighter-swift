import Foundation

/// Errors thrown by ``ShikiClient``.
///
/// Maps HTTP status codes from the Shiki Token Service to typed cases:
/// 400 -> ``invalidRequest``, ``unsupportedLanguage``, or ``unsupportedTheme``;
/// 413 -> ``payloadTooLarge``; 5xx -> ``serverError``.
public enum ShikiError: LocalizedError, Sendable {
    /// The request body failed server-side validation.
    case invalidRequest(details: String?)
    /// The requested language is not supported by the service.
    case unsupportedLanguage(language: String, supported: [String]?)
    /// The requested theme is not supported by the service.
    case unsupportedTheme(theme: String, supported: [String]?)
    /// The request body exceeds the 200 KB server limit.
    case payloadTooLarge
    /// The server returned a 5xx error.
    case serverError(message: String)
    /// A network-level failure (no response received).
    case networkError(underlying: any Error)
    /// The response JSON could not be decoded into the expected type.
    case decodingError(underlying: any Error)

    public var errorDescription: String? {
        switch self {
        case .invalidRequest(let details):
            return "Invalid request\(details.map { ": \($0)" } ?? "")"
        case .unsupportedLanguage(let lang, _):
            return "Unsupported language: \(lang)"
        case .unsupportedTheme(let theme, _):
            return "Unsupported theme: \(theme)"
        case .payloadTooLarge:
            return "Payload too large (maximum 200KB)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }

    /// Maps an HTTP status code and error response body to a typed ``ShikiError``.
    internal static func from(statusCode: Int, errorResponse: ErrorResponse) -> ShikiError {
        switch statusCode {
        case 413:
            return .payloadTooLarge
        case 400:
            let msg = errorResponse.error
            if msg.hasPrefix("Unsupported language:") {
                let lang = msg.replacingOccurrences(of: "Unsupported language: ", with: "")
                let supported = errorResponse.details?.components(separatedBy: ", ")
                return .unsupportedLanguage(language: lang, supported: supported)
            }
            if msg.hasPrefix("Unsupported theme:") {
                let theme = msg.replacingOccurrences(of: "Unsupported theme: ", with: "")
                let supported = errorResponse.details?.components(separatedBy: ", ")
                return .unsupportedTheme(theme: theme, supported: supported)
            }
            return .invalidRequest(details: errorResponse.details ?? errorResponse.error)
        default:
            return .serverError(message: errorResponse.error)
        }
    }
}
