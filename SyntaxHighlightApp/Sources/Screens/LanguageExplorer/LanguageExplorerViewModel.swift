import Foundation
import ShikiTokenSDK

/// Drives the language explorer: fetches available languages/themes and previews highlighting.
final class LanguageExplorerViewModel: ObservableObject {
    private let client: ShikiClient

    @Published var state: LoadingState<LanguagesResponse> = .idle
    @Published var selectedLanguage: String?
    @Published var previewState: LoadingState<HighlightResponse> = .idle
    @Published var selectedTheme: String = ShikiTheme.githubDark

    init(client: ShikiClient) {
        self.client = client
    }

    @MainActor
    func fetchLanguages() async {
        state = .loading
        do {
            let response = try await client.languages()
            state = .loaded(response)
        } catch {
            state = .error(error)
        }
    }

    @MainActor
    func previewLanguage(_ language: String) async {
        selectedLanguage = language
        previewState = .loading
        do {
            let sampleCode = "// Sample \(language) code\nfunction hello() {\n  return \"Hello, world!\";\n}\n"
            let request = HighlightRequest(
                code: sampleCode,
                language: language,
                theme: selectedTheme
            )
            let response = try await client.highlight(request)
            previewState = .loaded(response)
        } catch {
            previewState = .error(error)
        }
    }
}
