# Architecture

## System Overview

```
┌─────────────────────┐      HTTPS/JSON       ┌──────────────────────┐
│   iOS App           │ ───────────────────>   │  Shiki Token Service │
│   (SwiftUI)         │ <───────────────────   │  (TypeScript/Hono)   │
│                     │    colored tokens      │                      │
│  ┌────────────────┐ │                        │  ┌────────────────┐  │
│  │ ShikiTokenSDK  │ │                        │  │  Shiki Engine  │  │
│  │ (Swift Package)│ │                        │  │ (TextMate/WASM)│  │
│  └────────────────┘ │                        │  └────────────────┘  │
└─────────────────────┘                        └──────────────────────┘
```

Source code is sent to the [Shiki Token Service](https://github.com/hossain-khan/shiki-token-service), which tokenizes it using Shiki's TextMate grammar engine (the same one VS Code uses) and returns colored tokens as JSON. The iOS app renders these tokens as styled text.

**Companion projects:**
- [shiki-token-service](https://github.com/hossain-khan/shiki-token-service) — TypeScript microservice (Hono + Shiki)
- [android-syntax-highlighter-compose](https://github.com/hossain-khan/android-syntax-highlighter-compose) — Android equivalent (Jetpack Compose)

## ShikiTokenSDK (Swift Package)

Zero third-party dependencies. Targets iOS 16+ and macOS 13+.

### Package Layout

```
ShikiTokenSDK/
├── Sources/ShikiTokenSDK/
│   ├── Client/          HTTP client and error types
│   ├── Models/          Codable request/response structs and constants
│   └── UI/              SwiftUI rendering component
└── Tests/               URLProtocol-stubbed unit tests
```

### API Client (`ShikiClient`)

A `Sendable` class wrapping URLSession with async/await. Five public methods map 1:1 to API endpoints:

| Method | Endpoint | Returns |
|--------|----------|---------|
| `highlight(_:)` | `POST /highlight` | `HighlightResponse` — single-theme tokens |
| `highlightDual(_:)` | `POST /highlight/dual` | `HighlightDualResponse` — dark + light tokens |
| `highlightSemantic(_:)` | `POST /highlight/semantic` | `HighlightSemanticResponse` — typed tokens |
| `languages()` | `GET /languages` | `LanguagesResponse` — supported languages/themes |
| `health()` | `GET /health` | `HealthResponse` — service status |

Thread-safe by design: all stored properties are immutable after `init`. A custom `URLSession` can be injected for testing or proxy configuration.

### Error Handling (`ShikiError`)

All methods throw `ShikiError`, which maps HTTP status codes to typed cases:

- **400** -> `.invalidRequest`, `.unsupportedLanguage`, or `.unsupportedTheme`
- **413** -> `.payloadTooLarge`
- **5xx** -> `.serverError`
- Network failures -> `.networkError`
- JSON decode failures -> `.decodingError`

### Data Flow

```
HighlightRequest          JSON encode         POST /highlight
(code + language + theme) ──────────> HTTP ──────────────────>

                          JSON decode         [[Token]]
HighlightResponse <────────────────── HTTP <──────────────────
(language, theme, tokens)

tokens: [[Token]]                    AttributedString
(lines of tokens)    ──────────────> (foreground colors)  ──> SwiftUI Text
```

### Token Model Hierarchy

Three distinct token types, each returned by a different endpoint:

- **`Token`** — `{ text, color }` — single hex color per fragment
- **`DualToken`** — `{ text, darkColor, lightColor }` — both theme colors in one response
- **`SemanticToken`** — `{ text, type }` — classified by `TokenType` (keyword, string, etc.)

All token arrays are `[[T]]`: outer array = lines, inner array = tokens within that line.

### UI Component (`CodeHighlightView`)

A SwiftUI view with three initializers (one per token type). Internally builds an `AttributedString` with per-token foreground colors, rendered in a monospaced `Text` inside a bidirectional `ScrollView`.

The dual-token variant reads `@Environment(\.colorScheme)` and reactively switches between `darkColor` and `lightColor` when the system appearance changes — no re-fetch required.

### Constants

`ShikiLanguage` and `ShikiTheme` are uninhabited enums used as namespaces for string constants. They provide autocomplete without forcing consumers to use specific types.

## SyntaxHighlightApp (Demo)

### Architecture Pattern

MVVM with vanilla SwiftUI:
- **ViewModels**: `ObservableObject` classes with `@Published` state
- **Views**: SwiftUI structs using `@StateObject` to own their ViewModel
- **State**: Generic `LoadingState<T>` enum (idle / loading / loaded / error)
- **Navigation**: `NavigationStack` with `NavigationLink`

A single `ShikiClient` instance is created in the `@main` app struct and passed via initializer injection.

### Screen Map

```
HomeScreen
├── HighlightScreen       Single-theme highlighting
├── DualThemeScreen        Dark/light with side-by-side toggle
├── SemanticScreen         Token types with color legend
└── LanguageExplorerScreen Browse languages and themes
```

### Key Behaviors

- **Auto-highlight**: `.onChange` of picker selections triggers a new API call
- **Pull-to-refresh**: `.refreshable` modifier on loaded content
- **Copy with haptic**: `UIPasteboard` + `UIImpactFeedbackGenerator` (guarded by `#if canImport(UIKit)`)
- **Share as image**: `ImageRenderer` renders `CodeHighlightView` to `UIImage`
- **Live theme switching**: `DualThemeScreen` uses dual tokens — system appearance change instantly flips colors with zero network

## Dependencies

- **ShikiTokenSDK**: Foundation + SwiftUI only. Zero third-party dependencies.
- **SyntaxHighlightApp**: Depends on ShikiTokenSDK via local SPM path.
- **Build tool**: [xcodegen](https://github.com/yonaskolb/XcodeGen) generates the `.xcodeproj` from `project.yml`.

## Testing

- **SDK**: 25 unit tests (17 model decoding + 8 client tests using `URLProtocol` stubs)
- **App**: Manual testing via iOS Simulator. No automated UI tests.

Run SDK tests: `cd ShikiTokenSDK && swift test`
