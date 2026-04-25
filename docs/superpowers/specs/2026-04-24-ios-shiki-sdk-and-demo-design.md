# iOS Shiki Token SDK & Demo App — Design Spec

## Overview

Build an iOS SDK (`ShikiTokenSDK`) and a showcase SwiftUI demo app (`SyntaxHighlightApp`) for the [Shiki Token Service](https://syntax-highlight.gohk.xyz). The SDK provides a Swift async/await client for the API plus a ready-to-use SwiftUI view for rendering highlighted code. The demo app exercises all SDK features with iOS-specific touches like live dark/light mode switching via dual tokens.

**Target**: iOS 16+, Swift 5.9+, zero third-party dependencies.

## Repository Structure

```
ios-syntax-highlight/
├── ShikiTokenSDK/                    # Swift Package (SDK)
│   ├── Package.swift
│   ├── Sources/ShikiTokenSDK/
│   │   ├── Client/
│   │   │   ├── ShikiClient.swift     # Main entry point
│   │   │   └── ShikiError.swift      # Typed error enum
│   │   ├── Models/
│   │   │   ├── Requests.swift        # Request structs
│   │   │   ├── Responses.swift       # Response structs
│   │   │   ├── Tokens.swift          # Token, DualToken, SemanticToken
│   │   │   ├── TokenType.swift       # Semantic token type enum
│   │   │   ├── DebugInfo.swift       # Debug metadata
│   │   │   └── Constants.swift       # ShikiLanguage, ShikiTheme
│   │   └── UI/
│   │       └── CodeHighlightView.swift  # SwiftUI rendering component
│   └── Tests/ShikiTokenSDKTests/
│       ├── ShikiClientTests.swift
│       └── ModelDecodingTests.swift
└── SyntaxHighlightApp/               # Xcode project (demo app)
    └── SyntaxHighlightApp/
        ├── SyntaxHighlightApp.swift   # App entry point
        ├── Models/
        │   ├── LoadingState.swift     # Generic loading/loaded/error enum
        │   └── CodeSamples.swift      # Bundled code samples
        ├── Screens/
        │   ├── Home/
        │   │   ├── HomeScreen.swift
        │   │   └── HomeViewModel.swift
        │   ├── Highlight/
        │   │   ├── HighlightScreen.swift
        │   │   └── HighlightViewModel.swift
        │   ├── DualTheme/
        │   │   ├── DualThemeScreen.swift
        │   │   └── DualThemeViewModel.swift
        │   ├── Semantic/
        │   │   ├── SemanticScreen.swift
        │   │   └── SemanticViewModel.swift
        │   └── LanguageExplorer/
        │       ├── LanguageExplorerScreen.swift
        │       └── LanguageExplorerViewModel.swift
        └── Components/
            ├── MetricsBar.swift       # Performance metrics display
            ├── CodeSamplePicker.swift  # Language/sample selector
            └── ShareImage.swift       # Render CodeHighlightView to UIImage
```

## SDK Design: ShikiTokenSDK

### ShikiClient

```swift
public final class ShikiClient: Sendable {
    public init(
        baseURL: URL = URL(string: "https://syntax-highlight.gohk.xyz")!,
        urlSession: URLSession = .shared,
        timeoutInterval: TimeInterval = 30
    )

    public func highlight(_ request: HighlightRequest) async throws -> HighlightResponse
    public func highlightDual(_ request: HighlightDualRequest) async throws -> HighlightDualResponse
    public func highlightSemantic(_ request: HighlightSemanticRequest) async throws -> HighlightSemanticResponse
    public func languages() async throws -> LanguagesResponse
    public func health() async throws -> HealthResponse
}
```

- Uses `URLSession` with `async/await` (iOS 16+).
- Custom `URLSession` injection for testing.
- All methods throw `ShikiError`.

### ShikiError

```swift
public enum ShikiError: LocalizedError {
    case invalidRequest(details: String?)
    case unsupportedLanguage(language: String, supported: [String]?)
    case unsupportedTheme(theme: String, supported: [String]?)
    case payloadTooLarge
    case serverError(message: String)
    case networkError(underlying: Error)
    case decodingError(underlying: Error)
}
```

Parsed from the API's `{ "error": "...", "details": "..." }` shape, combined with HTTP status codes:
- 400 → `.invalidRequest`, `.unsupportedLanguage`, or `.unsupportedTheme` (determined by error message prefix)
- 413 → `.payloadTooLarge`
- 500 → `.serverError`
- URLSession failures → `.networkError`
- JSON decode failures → `.decodingError`

### Models

**Tokens:**

```swift
public struct Token: Codable, Hashable, Sendable {
    public let text: String
    public let color: String
}

public struct DualToken: Codable, Hashable, Sendable {
    public let text: String
    public let darkColor: String
    public let lightColor: String
}

public struct SemanticToken: Codable, Hashable, Sendable {
    public let text: String
    public let type: TokenType
}
```

**TokenType:**

```swift
public enum TokenType: String, Codable, CaseIterable, Sendable {
    case keyword, type, modifier, function, tag, attribute
    case parameter, variable, number, constant, string, comment
    case punctuation, plain
}
```

**Requests:**

```swift
public struct HighlightRequest: Encodable, Sendable {
    public let code: String
    public var language: String = ShikiLanguage.text
    public var theme: String = ShikiTheme.githubDark
    public var debug: Bool = false
}

public struct HighlightDualRequest: Encodable, Sendable {
    public let code: String
    public var language: String = ShikiLanguage.text
    public var darkTheme: String = ShikiTheme.githubDark
    public var lightTheme: String = ShikiTheme.githubLight
    public var debug: Bool = false
}

public struct HighlightSemanticRequest: Encodable, Sendable {
    public let code: String
    public var language: String = ShikiLanguage.text
    public var debug: Bool = false
}
```

**Responses:**

```swift
public struct HighlightResponse: Decodable, Sendable {
    public let language: String
    public let theme: String
    public let tokens: [[Token]]
    public let debug: DebugInfo?  // CodingKeys maps "_debug" → "debug"
}

public struct HighlightDualResponse: Decodable, Sendable {
    public let language: String
    public let darkTheme: String
    public let lightTheme: String
    public let tokens: [[DualToken]]
    public let debug: DebugInfo?
}

public struct HighlightSemanticResponse: Decodable, Sendable {
    public let language: String
    public let tokenTypes: [String]
    public let tokens: [[SemanticToken]]
    public let debug: DebugInfo?
}

public struct LanguagesResponse: Decodable, Sendable {
    public let languages: [String]
    public let themes: [String]
}

public struct HealthResponse: Decodable, Sendable {
    public let status: String
    public let version: String
}
```

**DebugInfo:**

```swift
public struct DebugInfo: Decodable, Sendable {
    public let totalMs: Double
    public let tokenizerMs: Double?
    public let requestBodyBytes: Int
    public let language: String?
    public let theme: String?
    public let darkTheme: String?
    public let lightTheme: String?
}
```

Mapped from JSON key `_debug` via `CodingKeys`.

**Constants:**

```swift
public enum ShikiLanguage {
    public static let text = "text"
    public static let kotlin = "kotlin"
    public static let java = "java"
    public static let python = "python"
    public static let javascript = "javascript"
    public static let typescript = "typescript"
    public static let swift = "swift"
    public static let go = "go"
    public static let rust = "rust"
    public static let json = "json"
    // ... all 32 languages
    public static let all: [String] = [...]
}

public enum ShikiTheme {
    public static let githubDark = "github-dark"
    public static let githubLight = "github-light"
    public static let oneDarkPro = "one-dark-pro"
    public static let dracula = "dracula"
    public static let minLight = "min-light"
    public static let darkPlus = "dark-plus"
    public static let lightPlus = "light-plus"
    public static let all: [String] = [...]
}
```

### UI Component: CodeHighlightView

```swift
public struct CodeHighlightView: View {
    // For single-theme tokens
    public init(tokens: [[Token]])

    // For dual-theme tokens — auto-selects color based on colorScheme
    public init(tokens: [[DualToken]])

    // For semantic tokens with custom color mapping
    public init(tokens: [[SemanticToken]], colorMapping: [TokenType: Color])
}
```

Implementation:
- Builds `AttributedString` from tokens, applying `foregroundColor` per token.
- Uses `.monospaced` system font (SF Mono on Apple platforms).
- Wraps in `ScrollView([.horizontal, .vertical])`.
- For `DualToken` variant, reads `@Environment(\.colorScheme)` and reactively switches between `darkColor`/`lightColor` with zero re-fetch.
- Parses hex color strings (`#RRGGBB`) to `Color` via a small extension.

### SDK Tests

- **ModelDecodingTests**: Verify all response structs decode correctly from JSON fixtures matching the real API responses. Test edge cases: empty color strings, missing `_debug` field, unknown token types.
- **ShikiClientTests**: Use `URLProtocol` stubbing to test request construction (correct URL, headers, JSON body) and response parsing without hitting the real API.

## Demo App Design: SyntaxHighlightApp

### Architecture

- SwiftUI with `ObservableObject` view models (`@StateObject` in views) for iOS 16 compatibility.
- `NavigationStack` for navigation.
- Generic `LoadingState<T>` enum: `.idle`, `.loading`, `.loaded(T)`, `.error(Error)`.
- Single shared `ShikiClient` instance created at app level and passed via environment or init injection.

### Screens

**HomeScreen**
- App title "Shiki Syntax Highlighter" with brief tagline.
- Navigation cards for each demo: Single Theme, Dual Theme, Semantic, Language Explorer.
- Each card has an icon, title, and one-line description.

**HighlightScreen (Single Theme)**
- Pickers: language (Menu picker), theme (Menu picker), code sample (segmented or menu).
- "Highlight" button or auto-highlight on selection change.
- Output: `CodeHighlightView` with single-theme tokens.
- Metrics bar below: network ms, total ms, lines, characters (from DebugInfo with `debug: true`).
- Toolbar: copy code, share as image.

**DualThemeScreen**
- Pickers: language, dark theme, light theme, code sample.
- Output: `CodeHighlightView` with dual tokens.
- **Showcase feature**: Toggle/split view showing dark and light side by side.
- **Live switching**: Changing system appearance instantly flips colors without re-fetch.
- Metrics bar with same stats.

**SemanticScreen**
- Pickers: language, code sample.
- Output: `CodeHighlightView` with semantic tokens and a configurable color palette.
- Token type legend: colored chips showing each `TokenType` and its assigned color.
- User can tap a token type chip to change its color (optional stretch goal).

**LanguageExplorerScreen**
- Fetches `/languages` on appear.
- Two sections: Languages (grid/list of all 32) and Themes (list of all 7).
- Tap a language → navigates to a detail view that highlights a generic sample in that language with the selected theme.

### iOS-Specific Showcase Features

1. **Live dark/light switching**: `DualThemeScreen` uses `@Environment(\.colorScheme)` so the `CodeHighlightView` reactively picks the correct color from dual tokens. System appearance change = instant color switch, zero network.
2. **Share as image**: Render the `CodeHighlightView` to a `UIImage` via `ImageRenderer` (iOS 16+) and present `ShareLink`/`UIActivityViewController`.
3. **Pull-to-refresh**: `.refreshable` on code output views to re-highlight and update metrics.
4. **Haptic feedback**: Light haptic on copy-to-clipboard via `UIImpactFeedbackGenerator`.

### Bundled Code Samples

Four samples matching the Android app:
- **Kotlin**: Coroutines + data class (~20 lines)
- **Python**: Async + dataclass (~20 lines)
- **JSON**: User list (~15 lines)
- **JavaScript**: Class + fetch (~20 lines)

Stored as static strings in `CodeSamples.swift` with associated `ShikiLanguage` values.

## Error Handling

- SDK throws typed `ShikiError` — demo app catches and displays user-friendly messages.
- Network errors show a retry button.
- No silent failures — all errors surface in the UI via `LoadingState.error`.

## Testing Strategy

**SDK:**
- Unit tests for model decoding (JSON fixtures).
- Unit tests for client request construction and error parsing (URLProtocol stubs).
- No integration tests hitting the real API in CI (can be run manually).

**Demo app:**
- Manual testing via Xcode previews and simulator.
- No automated UI tests in initial scope.
