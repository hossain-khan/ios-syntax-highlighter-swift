import Foundation
import ShikiTokenSDK

/// Drives the dual-theme screen: manages dark/light theme API calls and state.
final class DualThemeViewModel: ObservableObject {
    private let client: ShikiClient

    @Published var selectedSample: CodeSample = CodeSamples.kotlin
    @Published var darkTheme: String = ShikiTheme.githubDark
    @Published var lightTheme: String = ShikiTheme.githubLight
    @Published var state: LoadingState<HighlightDualResponse> = .idle
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
            let request = HighlightDualRequest(
                code: selectedSample.code,
                language: selectedSample.language,
                darkTheme: darkTheme,
                lightTheme: lightTheme,
                debug: true
            )
            let response = try await client.highlightDual(request)
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            elapsedMs = elapsed
            state = .loaded(response)
        } catch {
            state = .error(error)
        }
    }
}
