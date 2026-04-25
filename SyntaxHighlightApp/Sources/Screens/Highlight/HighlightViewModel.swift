import Foundation
import ShikiTokenSDK

/// Drives the single-theme highlight screen: manages API calls, timing, and state.
final class HighlightViewModel: ObservableObject {
    private let client: ShikiClient

    @Published var selectedSample: CodeSample = CodeSamples.kotlin
    @Published var selectedTheme: String = ShikiTheme.githubDark
    @Published var state: LoadingState<HighlightResponse> = .idle
    @Published var elapsedMs: Double?

    init(client: ShikiClient) {
        self.client = client
    }

    @MainActor
    func highlight() async {
        state = .loading
        elapsedMs = nil
        let start = CFAbsoluteTimeGetCurrent()
        do {
            let request = HighlightRequest(
                code: selectedSample.code,
                language: selectedSample.language,
                theme: selectedTheme,
                debug: true
            )
            let response = try await client.highlight(request)
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            elapsedMs = elapsed
            state = .loaded(response)
        } catch {
            state = .error(error)
        }
    }
}
