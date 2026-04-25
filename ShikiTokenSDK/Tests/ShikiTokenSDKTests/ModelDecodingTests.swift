import XCTest
import SwiftUI
@testable import ShikiTokenSDK

final class ModelDecodingTests: XCTestCase {
    private let decoder = JSONDecoder()

    // MARK: - Token

    func testDecodeToken() throws {
        let json = """
        {"text": "fun", "color": "#F97583"}
        """.data(using: .utf8)!

        let token = try decoder.decode(Token.self, from: json)
        XCTAssertEqual(token.text, "fun")
        XCTAssertEqual(token.color, "#F97583")
    }

    func testDecodeTokenEmptyColor() throws {
        let json = """
        {"text": " ", "color": ""}
        """.data(using: .utf8)!

        let token = try decoder.decode(Token.self, from: json)
        XCTAssertEqual(token.text, " ")
        XCTAssertEqual(token.color, "")
    }

    // MARK: - DualToken

    func testDecodeDualToken() throws {
        let json = """
        {"text": "val", "darkColor": "#F97583", "lightColor": "#D73A49"}
        """.data(using: .utf8)!

        let token = try decoder.decode(DualToken.self, from: json)
        XCTAssertEqual(token.text, "val")
        XCTAssertEqual(token.darkColor, "#F97583")
        XCTAssertEqual(token.lightColor, "#D73A49")
    }

    // MARK: - SemanticToken

    func testDecodeSemanticToken() throws {
        let json = """
        {"text": "const", "type": "keyword"}
        """.data(using: .utf8)!

        let token = try decoder.decode(SemanticToken.self, from: json)
        XCTAssertEqual(token.text, "const")
        XCTAssertEqual(token.type, .keyword)
    }

    // MARK: - TokenType

    func testDecodeAllTokenTypes() throws {
        let types = ["keyword", "type", "modifier", "function", "tag", "attribute",
                     "parameter", "variable", "number", "constant", "string", "comment",
                     "punctuation", "plain"]

        for typeString in types {
            let json = "\"\(typeString)\"".data(using: .utf8)!
            let tokenType = try decoder.decode(TokenType.self, from: json)
            XCTAssertEqual(tokenType.rawValue, typeString)
        }
    }

    // MARK: - DebugInfo

    func testDecodeDebugInfo() throws {
        let json = """
        {
            "totalMs": 1.2,
            "tokenizerMs": 0.5,
            "requestBodyBytes": 55,
            "language": "kotlin",
            "theme": "github-dark"
        }
        """.data(using: .utf8)!

        let info = try decoder.decode(DebugInfo.self, from: json)
        XCTAssertEqual(info.totalMs, 1.2)
        XCTAssertEqual(info.tokenizerMs, 0.5)
        XCTAssertEqual(info.requestBodyBytes, 55)
        XCTAssertEqual(info.language, "kotlin")
        XCTAssertEqual(info.theme, "github-dark")
        XCTAssertNil(info.darkTheme)
    }

    func testDecodeDebugInfoMinimalFields() throws {
        let json = """
        {
            "totalMs": 2.0,
            "requestBodyBytes": 100
        }
        """.data(using: .utf8)!

        let info = try decoder.decode(DebugInfo.self, from: json)
        XCTAssertEqual(info.totalMs, 2.0)
        XCTAssertNil(info.tokenizerMs)
        XCTAssertEqual(info.requestBodyBytes, 100)
        XCTAssertNil(info.language)
    }

    // MARK: - HighlightResponse

    func testDecodeHighlightResponse() throws {
        let json = """
        {
            "language": "kotlin",
            "theme": "github-dark",
            "tokens": [
                [
                    {"text": "fun", "color": "#F97583"},
                    {"text": " ", "color": "#E1E4E8"}
                ],
                [
                    {"text": "main", "color": "#B392F0"}
                ]
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(HighlightResponse.self, from: json)
        XCTAssertEqual(response.language, "kotlin")
        XCTAssertEqual(response.theme, "github-dark")
        XCTAssertEqual(response.tokens.count, 2)
        XCTAssertEqual(response.tokens[0].count, 2)
        XCTAssertEqual(response.tokens[0][0].text, "fun")
        XCTAssertNil(response.debug)
    }

    func testDecodeHighlightResponseWithDebug() throws {
        let json = """
        {
            "language": "kotlin",
            "theme": "github-dark",
            "tokens": [[{"text": "x", "color": "#FFF"}]],
            "_debug": {
                "totalMs": 1.5,
                "requestBodyBytes": 42,
                "language": "kotlin",
                "theme": "github-dark"
            }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(HighlightResponse.self, from: json)
        XCTAssertNotNil(response.debug)
        XCTAssertEqual(response.debug?.totalMs, 1.5)
    }

    // MARK: - HighlightDualResponse

    func testDecodeHighlightDualResponse() throws {
        let json = """
        {
            "language": "python",
            "darkTheme": "github-dark",
            "lightTheme": "github-light",
            "tokens": [
                [
                    {"text": "def", "darkColor": "#F97583", "lightColor": "#D73A49"}
                ]
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(HighlightDualResponse.self, from: json)
        XCTAssertEqual(response.language, "python")
        XCTAssertEqual(response.darkTheme, "github-dark")
        XCTAssertEqual(response.lightTheme, "github-light")
        XCTAssertEqual(response.tokens[0][0].darkColor, "#F97583")
        XCTAssertNil(response.debug)
    }

    // MARK: - HighlightSemanticResponse

    func testDecodeHighlightSemanticResponse() throws {
        let json = """
        {
            "language": "javascript",
            "tokenTypes": ["keyword", "plain", "variable"],
            "tokens": [
                [
                    {"text": "const", "type": "keyword"},
                    {"text": " ", "type": "plain"},
                    {"text": "x", "type": "variable"}
                ]
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(HighlightSemanticResponse.self, from: json)
        XCTAssertEqual(response.language, "javascript")
        XCTAssertEqual(response.tokenTypes, ["keyword", "plain", "variable"])
        XCTAssertEqual(response.tokens[0][0].type, .keyword)
        XCTAssertNil(response.debug)
    }

    // MARK: - LanguagesResponse

    func testDecodeLanguagesResponse() throws {
        let json = """
        {
            "languages": ["kotlin", "swift", "python"],
            "themes": ["github-dark", "github-light"]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(LanguagesResponse.self, from: json)
        XCTAssertEqual(response.languages.count, 3)
        XCTAssertEqual(response.themes.count, 2)
    }

    // MARK: - HealthResponse

    func testDecodeHealthResponse() throws {
        let json = """
        {"status": "ok", "version": "1.2.0"}
        """.data(using: .utf8)!

        let response = try decoder.decode(HealthResponse.self, from: json)
        XCTAssertEqual(response.status, "ok")
        XCTAssertEqual(response.version, "1.2.0")
    }

    // MARK: - Color+Hex

    func testHexColorParsing() {
        let color = Color(hex: "#F97583")
        XCTAssertNotNil(color)
    }

    func testHexColorParsingWithoutHash() {
        let color = Color(hex: "F97583")
        XCTAssertNotNil(color)
    }

    func testHexColorParsingInvalid() {
        let color = Color(hex: "not-a-color")
        XCTAssertNil(color)
    }

    func testHexColorParsingEmpty() {
        let color = Color(hex: "")
        XCTAssertNil(color)
    }

    // MARK: - Constants

    func testShikiLanguageAllContains32Languages() {
        XCTAssertEqual(ShikiLanguage.all.count, 32)
        XCTAssertTrue(ShikiLanguage.all.contains(ShikiLanguage.kotlin))
        XCTAssertTrue(ShikiLanguage.all.contains(ShikiLanguage.swift))
        XCTAssertTrue(ShikiLanguage.all.contains(ShikiLanguage.text))
    }

    func testShikiThemeAllContains7Themes() {
        XCTAssertEqual(ShikiTheme.all.count, 7)
        XCTAssertTrue(ShikiTheme.all.contains(ShikiTheme.githubDark))
        XCTAssertTrue(ShikiTheme.all.contains(ShikiTheme.githubLight))
        XCTAssertTrue(ShikiTheme.all.contains(ShikiTheme.dracula))
    }

    func testShikiLanguageNoDuplicates() {
        let unique = Set(ShikiLanguage.all)
        XCTAssertEqual(unique.count, ShikiLanguage.all.count)
    }

    func testShikiThemeNoDuplicates() {
        let unique = Set(ShikiTheme.all)
        XCTAssertEqual(unique.count, ShikiTheme.all.count)
    }

    // MARK: - Request encoding

    func testHighlightRequestEncodesAllFields() throws {
        let request = HighlightRequest(code: "let x = 1", language: ShikiLanguage.swift, theme: ShikiTheme.dracula, debug: true)
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["code"] as? String, "let x = 1")
        XCTAssertEqual(dict["language"] as? String, "swift")
        XCTAssertEqual(dict["theme"] as? String, "dracula")
        XCTAssertEqual(dict["debug"] as? Bool, true)
    }

    func testHighlightRequestDefaults() throws {
        let request = HighlightRequest(code: "x")
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["language"] as? String, "text")
        XCTAssertEqual(dict["theme"] as? String, "github-dark")
        XCTAssertEqual(dict["debug"] as? Bool, false)
    }

    func testHighlightDualRequestDefaults() throws {
        let request = HighlightDualRequest(code: "x")
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["darkTheme"] as? String, "github-dark")
        XCTAssertEqual(dict["lightTheme"] as? String, "github-light")
    }

    func testHighlightSemanticRequestHasNoThemeField() throws {
        let request = HighlightSemanticRequest(code: "x")
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertNil(dict["theme"])
        XCTAssertNil(dict["darkTheme"])
    }
}
