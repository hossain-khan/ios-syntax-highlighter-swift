import SwiftUI
import ShikiTokenSDK

/// Browse all supported languages and themes with tap-to-preview highlighting.
struct LanguageExplorerScreen: View {
    @StateObject private var viewModel: LanguageExplorerViewModel

    init(client: ShikiClient) {
        _viewModel = StateObject(wrappedValue: LanguageExplorerViewModel(client: client))
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Loading languages...")
            case .loaded(let response):
                List {
                    Section("Languages (\(response.languages.count))") {
                        ForEach(response.languages, id: \.self) { language in
                            NavigationLink(language) {
                                languageDetail(language)
                            }
                        }
                    }
                    Section("Themes (\(response.themes.count))") {
                        ForEach(response.themes, id: \.self) { theme in
                            HStack {
                                Text(theme)
                                Spacer()
                                if theme == viewModel.selectedTheme {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectedTheme = theme
                            }
                        }
                    }
                }
            case .error(let error):
                VStack(spacing: 12) {
                    Text(error.localizedDescription)
                    Button("Retry") {
                        Task { await viewModel.fetchLanguages() }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle("Languages")
        .task {
            await viewModel.fetchLanguages()
        }
    }

    private func languageDetail(_ language: String) -> some View {
        VStack {
            switch viewModel.previewState {
            case .idle, .loading:
                ProgressView()
            case .loaded(let response):
                CodeHighlightView(tokens: response.tokens)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            case .error(let error):
                Text(error.localizedDescription)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(language)
        .task {
            await viewModel.previewLanguage(language)
        }
    }
}
