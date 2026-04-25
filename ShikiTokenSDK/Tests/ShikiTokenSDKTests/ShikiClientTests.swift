import XCTest
@testable import ShikiTokenSDK

final class ShikiClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    private func makeClient() -> ShikiClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        return ShikiClient(
            baseURL: URL(string: "https://test.example.com")!,
            urlSession: session
        )
    }

    // MARK: - highlight

    func testHighlightSendsCorrectRequest() async throws {
        let responseJSON = """
        {
            "language": "kotlin",
            "theme": "github-dark",
            "tokens": [[{"text": "fun", "color": "#F97583"}]]
        }
        """.data(using: .utf8)!

        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/highlight")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

            let body = try! JSONSerialization.jsonObject(with: request.httpBodyStreamData()!) as! [String: Any]
            XCTAssertEqual(body["code"] as? String, "fun main() {}")
            XCTAssertEqual(body["language"] as? String, "kotlin")
            XCTAssertEqual(body["theme"] as? String, "github-dark")

            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseJSON)
        }

        let client = makeClient()
        let request = HighlightRequest(code: "fun main() {}", language: ShikiLanguage.kotlin)
        let response = try await client.highlight(request)

        XCTAssertEqual(response.language, "kotlin")
        XCTAssertEqual(response.tokens[0][0].text, "fun")
    }

    // MARK: - highlightDual

    func testHighlightDualSendsCorrectRequest() async throws {
        let responseJSON = """
        {
            "language": "python",
            "darkTheme": "github-dark",
            "lightTheme": "github-light",
            "tokens": [[{"text": "def", "darkColor": "#F97583", "lightColor": "#D73A49"}]]
        }
        """.data(using: .utf8)!

        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/highlight/dual")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseJSON)
        }

        let client = makeClient()
        let request = HighlightDualRequest(code: "def foo(): pass", language: ShikiLanguage.python)
        let response = try await client.highlightDual(request)

        XCTAssertEqual(response.language, "python")
        XCTAssertEqual(response.tokens[0][0].darkColor, "#F97583")
    }

    // MARK: - highlightSemantic

    func testHighlightSemanticSendsCorrectRequest() async throws {
        let responseJSON = """
        {
            "language": "javascript",
            "tokenTypes": ["keyword", "plain"],
            "tokens": [[{"text": "const", "type": "keyword"}]]
        }
        """.data(using: .utf8)!

        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/highlight/semantic")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseJSON)
        }

        let client = makeClient()
        let request = HighlightSemanticRequest(code: "const x = 1", language: ShikiLanguage.javascript)
        let response = try await client.highlightSemantic(request)

        XCTAssertEqual(response.tokens[0][0].type, .keyword)
    }

    // MARK: - languages

    func testLanguagesFetchesCorrectEndpoint() async throws {
        let responseJSON = """
        {"languages": ["kotlin", "swift"], "themes": ["github-dark"]}
        """.data(using: .utf8)!

        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/languages")
            XCTAssertEqual(request.httpMethod, "GET")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseJSON)
        }

        let client = makeClient()
        let response = try await client.languages()
        XCTAssertEqual(response.languages, ["kotlin", "swift"])
    }

    // MARK: - health

    func testHealthFetchesCorrectEndpoint() async throws {
        let responseJSON = """
        {"status": "ok", "version": "1.2.0"}
        """.data(using: .utf8)!

        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/health")
            XCTAssertEqual(request.httpMethod, "GET")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseJSON)
        }

        let client = makeClient()
        let response = try await client.health()
        XCTAssertEqual(response.status, "ok")
    }

    // MARK: - Error handling

    func testUnsupportedLanguageThrowsError() async {
        let responseJSON = """
        {"error": "Unsupported language: brainfuck", "details": "Supported languages: kotlin, swift"}
        """.data(using: .utf8)!

        MockURLProtocol.handler = { request in
            return (HTTPURLResponse(url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil)!, responseJSON)
        }

        let client = makeClient()
        do {
            _ = try await client.highlight(HighlightRequest(code: "x", language: "brainfuck"))
            XCTFail("Expected error")
        } catch let error as ShikiError {
            if case .unsupportedLanguage(let lang, _) = error {
                XCTAssertEqual(lang, "brainfuck")
            } else {
                XCTFail("Wrong error case: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testPayloadTooLargeThrowsError() async {
        let responseJSON = """
        {"error": "Payload too large", "details": "Maximum body size is 200KB"}
        """.data(using: .utf8)!

        MockURLProtocol.handler = { request in
            return (HTTPURLResponse(url: request.url!, statusCode: 413, httpVersion: nil, headerFields: nil)!, responseJSON)
        }

        let client = makeClient()
        do {
            _ = try await client.highlight(HighlightRequest(code: "x"))
            XCTFail("Expected error")
        } catch let error as ShikiError {
            if case .payloadTooLarge = error {
                // pass
            } else {
                XCTFail("Wrong error case: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Request encoding

    func testHighlightDualRequestEncodesCorrectFields() async throws {
        let responseJSON = """
        {
            "language": "swift",
            "darkTheme": "dracula",
            "lightTheme": "min-light",
            "tokens": [[{"text": "let", "darkColor": "#FF79C6", "lightColor": "#D73A49"}]]
        }
        """.data(using: .utf8)!

        MockURLProtocol.handler = { request in
            let body = try! JSONSerialization.jsonObject(with: request.httpBodyStreamData()!) as! [String: Any]
            XCTAssertEqual(body["code"] as? String, "let x = 1")
            XCTAssertEqual(body["language"] as? String, "swift")
            XCTAssertEqual(body["darkTheme"] as? String, "dracula")
            XCTAssertEqual(body["lightTheme"] as? String, "min-light")
            XCTAssertEqual(body["debug"] as? Bool, true)
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseJSON)
        }

        let client = makeClient()
        let request = HighlightDualRequest(
            code: "let x = 1",
            language: ShikiLanguage.swift,
            darkTheme: ShikiTheme.dracula,
            lightTheme: ShikiTheme.minLight,
            debug: true
        )
        let response = try await client.highlightDual(request)
        XCTAssertEqual(response.darkTheme, "dracula")
    }

    func testHighlightSemanticRequestEncodesCorrectFields() async throws {
        let responseJSON = """
        {
            "language": "python",
            "tokenTypes": ["keyword"],
            "tokens": [[{"text": "def", "type": "keyword"}]]
        }
        """.data(using: .utf8)!

        MockURLProtocol.handler = { request in
            let body = try! JSONSerialization.jsonObject(with: request.httpBodyStreamData()!) as! [String: Any]
            XCTAssertEqual(body["code"] as? String, "def foo(): pass")
            XCTAssertEqual(body["language"] as? String, "python")
            XCTAssertEqual(body["debug"] as? Bool, false)
            XCTAssertNil(body["theme"])
            XCTAssertNil(body["darkTheme"])
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseJSON)
        }

        let client = makeClient()
        let request = HighlightSemanticRequest(code: "def foo(): pass", language: ShikiLanguage.python)
        _ = try await client.highlightSemantic(request)
    }

    // MARK: - Error handling (additional)

    func testUnsupportedThemeThrowsError() async {
        let responseJSON = """
        {"error": "Unsupported theme: monokai", "details": "Supported themes: github-dark, github-light"}
        """.data(using: .utf8)!

        MockURLProtocol.handler = { request in
            return (HTTPURLResponse(url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil)!, responseJSON)
        }

        let client = makeClient()
        do {
            _ = try await client.highlight(HighlightRequest(code: "x", theme: "monokai"))
            XCTFail("Expected error")
        } catch let error as ShikiError {
            if case .unsupportedTheme(let theme, let supported) = error {
                XCTAssertEqual(theme, "monokai")
                XCTAssertEqual(supported, ["Supported themes: github-dark", "github-light"])
            } else {
                XCTFail("Wrong error case: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testInvalidRequestThrowsError() async {
        let responseJSON = """
        {"error": "Invalid request", "details": "code is required"}
        """.data(using: .utf8)!

        MockURLProtocol.handler = { request in
            return (HTTPURLResponse(url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil)!, responseJSON)
        }

        let client = makeClient()
        do {
            _ = try await client.highlight(HighlightRequest(code: ""))
            XCTFail("Expected error")
        } catch let error as ShikiError {
            if case .invalidRequest(let details) = error {
                XCTAssertEqual(details, "code is required")
            } else {
                XCTFail("Wrong error case: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testNetworkErrorThrowsError() async {
        MockURLProtocol.handler = { request in
            throw URLError(.notConnectedToInternet)
        }

        let client = makeClient()
        do {
            _ = try await client.highlight(HighlightRequest(code: "x"))
            XCTFail("Expected error")
        } catch let error as ShikiError {
            if case .networkError(let underlying) = error {
                XCTAssertTrue((underlying as? URLError)?.code == .notConnectedToInternet)
            } else {
                XCTFail("Wrong error case: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testMalformedJSONThrowsDecodingError() async {
        let malformedJSON = "not valid json".data(using: .utf8)!

        MockURLProtocol.handler = { request in
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, malformedJSON)
        }

        let client = makeClient()
        do {
            _ = try await client.highlight(HighlightRequest(code: "x"))
            XCTFail("Expected error")
        } catch let error as ShikiError {
            if case .decodingError = error {
                // pass
            } else {
                XCTFail("Wrong error case: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testNonJSONErrorResponseFallsBackToStatusCode() async {
        let htmlBody = "<html><body>Bad Gateway</body></html>".data(using: .utf8)!

        MockURLProtocol.handler = { request in
            return (HTTPURLResponse(url: request.url!, statusCode: 502, httpVersion: nil, headerFields: nil)!, htmlBody)
        }

        let client = makeClient()
        do {
            _ = try await client.highlight(HighlightRequest(code: "x"))
            XCTFail("Expected error")
        } catch let error as ShikiError {
            if case .serverError(let msg) = error {
                XCTAssertEqual(msg, "HTTP 502")
            } else {
                XCTFail("Wrong error case: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Error descriptions

    func testShikiErrorDescriptions() {
        let cases: [(ShikiError, String)] = [
            (.invalidRequest(details: "bad input"), "Invalid request: bad input"),
            (.invalidRequest(details: nil), "Invalid request"),
            (.unsupportedLanguage(language: "brainfuck", supported: nil), "Unsupported language: brainfuck"),
            (.unsupportedTheme(theme: "monokai", supported: nil), "Unsupported theme: monokai"),
            (.payloadTooLarge, "Payload too large (maximum 200KB)"),
            (.serverError(message: "fail"), "Server error: fail"),
        ]
        for (error, expected) in cases {
            XCTAssertEqual(error.errorDescription, expected)
        }
    }

    func testServerErrorThrowsError() async {
        let responseJSON = """
        {"error": "Highlighting failed"}
        """.data(using: .utf8)!

        MockURLProtocol.handler = { request in
            return (HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!, responseJSON)
        }

        let client = makeClient()
        do {
            _ = try await client.highlight(HighlightRequest(code: "x"))
            XCTFail("Expected error")
        } catch let error as ShikiError {
            if case .serverError(let msg) = error {
                XCTAssertEqual(msg, "Highlighting failed")
            } else {
                XCTFail("Wrong error case: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}

// MARK: - MockURLProtocol

final class MockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    static func reset() {
        handler = nil
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.handler else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

extension URLRequest {
    func httpBodyStreamData() -> Data? {
        guard let stream = httpBodyStream else { return httpBody }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read > 0 {
                data.append(buffer, count: read)
            }
        }
        return data
    }
}
