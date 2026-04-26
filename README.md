# iOS Syntax Highlight

A showcase iOS app demonstrating syntax highlighting powered by the [Shiki Token Service](https://github.com/hossain-khan/shiki-token-service) — the same TextMate grammar engine used by VS Code.

This is the iOS counterpart to [android-syntax-highlighter-compose](https://github.com/hossain-khan/android-syntax-highlighter-compose).

## Structure

| Component | Description |
|-----------|-------------|
| `ShikiTokenSDK/` | Swift Package — async/await API client + SwiftUI `CodeHighlightView` |
| `SyntaxHighlightApp/` | Demo app exercising all SDK features |


### Demo Screenshots

| Test Different APIs | Single Theme API | Doual Theme API |
| ---- | ---- | ---- |
| <img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 Pro - 2026-04-25 at 21 37 42" src="https://github.com/user-attachments/assets/7f6c005e-7203-4c9b-a30c-9e97b58d2204" /> | <img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 Pro - 2026-04-25 at 21 37 59" src="https://github.com/user-attachments/assets/44cc73c1-a00a-4d8f-b7c9-844521f13ad7" /> | <img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 Pro - 2026-04-25 at 21 38 56" src="https://github.com/user-attachments/assets/b394d877-21a0-4c5c-8c4c-722bef1c749b" /> |




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

---

> [!NOTE]
> This project was developed with the assistance of AI coding agents (GitHub Copilot).
> Code, architecture, tests, and documentation were generated or refined through
> AI-assisted pair programming. Review accordingly before using in production.
