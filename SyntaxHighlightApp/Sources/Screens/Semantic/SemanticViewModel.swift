import Foundation
import SwiftUI
import ShikiTokenSDK

/// Drives the semantic screen: manages semantic highlighting and token color mapping.
final class SemanticViewModel: ObservableObject {
    private let client: ShikiClient

    @Published var selectedSample: CodeSample = CodeSamples.kotlin
    @Published var state: LoadingState<HighlightSemanticResponse> = .idle
    @Published var elapsedMs: Double?
    @Published var colorMapping: [TokenType: Color] = SemanticViewModel.defaultColorMapping

    static let defaultColorMapping: [TokenType: Color] = [
        .keyword: .purple,
        .type: .cyan,
        .modifier: .purple.opacity(0.8),
        .function: .blue,
        .tag: .red,
        .attribute: .orange,
        .parameter: .orange.opacity(0.8),
        .variable: .primary,
        .number: .green,
        .constant: .green.opacity(0.8),
        .string: .red.opacity(0.8),
        .comment: .gray,
        .punctuation: .secondary,
        .plain: .primary,
    ]

    init(client: ShikiClient) {
        self.client = client
    }

    @MainActor
    func highlight() async {
        state = .loading
        elapsedMs = nil
        let start = CFAbsoluteTimeGetCurrent()
        do {
            let request = HighlightSemanticRequest(
                code: selectedSample.code,
                language: selectedSample.language,
                debug: true
            )
            let response = try await client.highlightSemantic(request)
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            elapsedMs = elapsed
            state = .loaded(response)
        } catch {
            state = .error(error)
        }
    }
}
