# iOS Syntax Highlight

A showcase iOS app demonstrating syntax highlighting powered by the [Shiki Token Service](https://github.com/hossain-khan/shiki-token-service) — the same TextMate grammar engine used by VS Code.

This is the iOS counterpart to [android-syntax-highlighter-compose](https://github.com/hossain-khan/android-syntax-highlighter-compose).

## Structure

| Component | Description |
|-----------|-------------|
| `ShikiTokenSDK/` | Swift Package — async/await API client + SwiftUI `CodeHighlightView` |
| `SyntaxHighlightApp/` | Demo app exercising all SDK features |

## SDK Usage

```swift
import ShikiTokenSDK

let client = ShikiClient()

// Single theme
let response = try await client.highlight(
    HighlightRequest(code: "print('hello')", language: ShikiLanguage.python)
)

// Dual theme (dark + light in one request)
let dual = try await client.highlightDual(
    HighlightDualRequest(code: "val x = 1", language: ShikiLanguage.kotlin)
)

// Semantic tokens
let semantic = try await client.highlightSemantic(
    HighlightSemanticRequest(code: "const x = 1", language: ShikiLanguage.javascript)
)
```

### SwiftUI

```swift
// Renders highlighted code with automatic dark/light switching
CodeHighlightView(tokens: dualResponse.tokens)
```

## Demo App Screens

- **Single Theme** — Highlight with one color theme, metrics display
- **Dual Theme** — Dark & light tokens, side-by-side preview, instant mode switching
- **Semantic** — Token types with custom color palette and legend
- **Language Explorer** — Browse all 32 languages and 7 themes

## Getting Started

### Prerequisites

- macOS with Xcode 15+ installed
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Run the Demo App

```bash
git clone git@github.com:hossain-khan/ios-syntax-highlight.git
cd ios-syntax-highlight/SyntaxHighlightApp
xcodegen generate
open SyntaxHighlightApp.xcodeproj
```

In Xcode, select an iOS 16+ simulator and press **Cmd+R** to build and run.

### Run SDK Tests

```bash
cd ShikiTokenSDK
swift test
```

### Add the SDK to Your Project

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/hossain-khan/ios-syntax-highlight.git", from: "1.0.0")
]
```

Then add `"ShikiTokenSDK"` to your target's dependencies.

## Requirements

- iOS 16+ / macOS 13+
- Xcode 15+
- Swift 5.9+

## License

MIT
