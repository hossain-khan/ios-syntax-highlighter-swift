import Foundation

/// Async/await client for the Shiki Token Service API.
///
/// Wraps all five API endpoints with typed Swift requests and responses.
/// Thread-safe (`Sendable`) — a single instance can be shared across the app.
///
/// ```swift
/// let client = ShikiClient()
/// let response = try await client.highlight(
///     HighlightRequest(code: "print('hello')", language: ShikiLanguage.python)
/// )
/// ```
///
/// - Note: Requires network access. All methods throw ``ShikiError`` on failure.
public final class ShikiClient: Sendable {
    private let baseURL: URL
    private let urlSession: URLSession
    private let timeoutInterval: TimeInterval

    /// Creates a client for the Shiki Token Service.
    /// - Parameters:
    ///   - baseURL: The service base URL. Defaults to the hosted instance.
    ///   - urlSession: Custom session for testing or proxy configuration.
    ///   - timeoutInterval: Request timeout in seconds. Defaults to 30.
    public init(
        baseURL: URL = URL(string: "https://syntax-highlight.gohk.xyz")!,
        urlSession: URLSession = .shared,
        timeoutInterval: TimeInterval = 30
    ) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.timeoutInterval = timeoutInterval
    }

    /// Highlights code with a single color theme.
    public func highlight(_ request: HighlightRequest) async throws -> HighlightResponse {
        try await post(path: "/highlight", body: request)
    }

    /// Highlights code with both dark and light themes in a single request.
    public func highlightDual(_ request: HighlightDualRequest) async throws -> HighlightDualResponse {
        try await post(path: "/highlight/dual", body: request)
    }

    /// Highlights code with semantic token types instead of colors.
    public func highlightSemantic(_ request: HighlightSemanticRequest) async throws -> HighlightSemanticResponse {
        try await post(path: "/highlight/semantic", body: request)
    }

    /// Fetches all supported languages and themes from the service.
    public func languages() async throws -> LanguagesResponse {
        try await get(path: "/languages")
    }

    /// Checks the health and version of the Shiki Token Service.
    public func health() async throws -> HealthResponse {
        try await get(path: "/health")
    }

    // MARK: - Private

    private func get<T: Decodable>(path: String) async throws -> T {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(path))
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = timeoutInterval
        return try await perform(urlRequest)
    }

    private func post<Body: Encodable, T: Decodable>(path: String, body: Body) async throws -> T {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(path))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = timeoutInterval
        urlRequest.httpBody = try JSONEncoder().encode(body)
        return try await perform(urlRequest)
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            throw ShikiError.networkError(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ShikiError.networkError(underlying: URLError(.badServerResponse))
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw ShikiError.from(statusCode: httpResponse.statusCode, errorResponse: errorResponse)
            }
            throw ShikiError.serverError(message: "HTTP \(httpResponse.statusCode)")
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ShikiError.decodingError(underlying: error)
        }
    }
}
