# Adding a Syntax Highlighting Library

A guide for integrating an alternative syntax highlighting approach alongside the existing Shiki Token Service.

## Current Approach: Shiki Token Service (Remote)

Source code is sent to a hosted API, tokenized server-side by Shiki using TextMate grammars, and returned as colored JSON tokens.

| Strength | Limitation |
|----------|-----------|
| VS Code-quality grammar accuracy | Requires network connectivity |
| 32+ languages, 7 themes | Latency (50-200ms per request) |
| Zero on-device processing | Server dependency |
| Dual-theme in a single request | 200 KB request size limit |

## Step-by-Step Integration

### 1. Define the Adapter Protocol

Create a protocol that abstracts highlighting, producing the same token output the SDK already uses:

```swift
import ShikiTokenSDK

protocol SyntaxHighlighter {
    /// Highlights code and returns lines of tokens.
    func highlight(code: String, language: String, theme: String) async throws -> [[Token]]
    
    /// Which languages this highlighter supports.
    var supportedLanguages: [String] { get }
}
```

`ShikiClient` already fits this shape — its `highlight()` method returns `HighlightResponse` containing `[[Token]]`.

### 2. Implement the Adapter

Create a new file (e.g., `Sources/Highlighters/MyLibraryHighlighter.swift`) that wraps the library behind the protocol:

```swift
struct MyLibraryHighlighter: SyntaxHighlighter {
    var supportedLanguages: [String] { ["swift", "python", "javascript"] }
    
    func highlight(code: String, language: String, theme: String) async throws -> [[Token]] {
        // 1. Call the library's native API
        // 2. Convert its output to [[Token]]
        // 3. Return
    }
}
```

**Output conversion** is the main work. Libraries produce different outputs:

| Library Output | Conversion Strategy |
|---|---|
| `NSAttributedString` (Highlightr, Splash) | Enumerate attribute runs, extract `.foregroundColor`, convert UIColor to hex string, create `Token(text:color:)` per run |
| Tree-sitter nodes | Walk the syntax tree, map node types to colors via a theme map, create `Token` per leaf node |
| HTML (some JS-based engines) | Parse `<span style="color:...">` tags, extract text and color |

### 3. Handle Token Type Differences

The SDK has three token types. Choose the simplest that fits:

- **`Token`** (text + single hex color) — use if the library produces colored output
- **`SemanticToken`** (text + `TokenType`) — use if the library classifies tokens by type without colors
- **`DualToken`** (text + dark + light hex) — use if the library can run two themes in one pass

Most on-device libraries produce single-themed output, so `[[Token]]` is the natural fit.

### 4. Wire Into the Demo App

Add a way to switch between engines in the app:

1. Add an enum for the available engines:
   ```swift
   enum HighlightEngine: String, CaseIterable {
       case shikiRemote = "Shiki (Remote)"
       case myLibrary = "MyLibrary (On-Device)"
   }
   ```

2. Update ViewModels to accept the protocol instead of `ShikiClient` directly.

3. Add a picker or segmented control to switch engines.

4. **No view changes needed** — `CodeHighlightView` already renders `[[Token]]` regardless of where they came from.

### 5. Add Comparison Metrics

The existing `MetricsBar` shows network and server timing. For on-device libraries, add:

- **Tokenization time**: `CFAbsoluteTimeGetCurrent()` around the highlight call
- **Binary size impact**: note the library's contribution to the IPA
- **Memory usage**: profile with Instruments if needed

The Android counterpart ([android-syntax-highlighter-compose](https://github.com/hossain-khan/android-syntax-highlighter-compose)) already compares server-driven Shiki with on-device kotlin-textmate — use it as a reference for comparison UI patterns.

## Comparison Checklist

When evaluating a candidate library, measure these dimensions:

| Dimension | What to Measure |
|---|---|
| Language coverage | How many of the 32 `ShikiLanguage` values are supported? |
| Theme support | Can it produce themed colors? How many themes? |
| Token granularity | Per-token coloring or line-level? |
| Dual-theme | Can it produce dark + light in one pass? |
| Semantic types | Does it classify tokens (keyword, string, etc.)? |
| Latency | Time to highlight each of the 4 bundled `CodeSamples` |
| Offline capable | Works without network? |
| Binary size impact | Library size added to the app bundle |
| Dependencies | Transitive dependencies pulled in |
| Maintenance | Last release date, open issues, bus factor |

## Candidate Libraries

### HighlightSwift (highlight.js via JavaScriptCore)
- **Package**: SPM, wraps highlight.js
- **Pro**: 50+ languages, 30+ themes, SwiftUI `CodeText` view included
- **Con**: JavaScriptCore overhead (~50ms for 500 lines), different grammar engine than TextMate
- **Adapter work**: Medium — produces `AttributedString`, needs color extraction

### Splash (Swift-native tokenizer)
- **Package**: SPM, pure Swift
- **Pro**: Zero dependencies, very fast, lightweight
- **Con**: Swift-only language support
- **Adapter work**: Low — produces `NSAttributedString` with color attributes

### Neon (tree-sitter via SwiftTreeSitter)
- **Package**: SPM, wraps tree-sitter
- **Pro**: Incremental parsing, very fast, broad language support
- **Con**: Requires bundled grammar files per language, complex integration, no built-in themes
- **Adapter work**: High — need grammar files, theme-to-color mapping, tree walking

### syntect (Rust, via C FFI)
- **Pro**: Full TextMate grammar support (same as Shiki), battle-tested (used by bat, Sourcegraph)
- **Con**: Requires Rust toolchain for building, C FFI bridge work
- **Adapter work**: High — Rust-to-C-to-Swift bridge, but produces the closest output to Shiki

## Architecture Decision: Local vs. Remote

| Question | Favors Remote (Shiki) | Favors Local (On-Device) |
|---|---|---|
| Is offline support required? | No | Yes |
| Is VS Code grammar accuracy required? | Yes | Depends on library |
| Is app binary size constrained? | Yes (0 KB added) | Budget for 1-5 MB |
| Is latency critical? | Tolerable (50-200ms) | Yes (<10ms preferred) |
| Need both approaches as fallback? | Consider remote-first with local fallback | -- |

For a comparison app (like this project), running both simultaneously and showing metrics side by side is the most informative approach.
