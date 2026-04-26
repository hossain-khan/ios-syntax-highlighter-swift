import SwiftUI
import ShikiTokenSDK

/// Single-theme highlighting with language/theme pickers, metrics, copy, and share.
struct HighlightScreen: View {
    @StateObject private var viewModel: HighlightViewModel

    init(client: ShikiClient) {
        _viewModel = StateObject(wrappedValue: HighlightViewModel(client: client))
    }

    var body: some View {
        VStack(spacing: 0) {
            pickerSection
            Divider()
            contentSection
        }
        .navigationTitle("Single Theme")
        .toolbar {
            if let response = viewModel.state.value {
                Button {
                    copyToClipboard(tokens: response.tokens)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
            }
        }
        .task {
            await viewModel.highlight()
        }
    }

    private var pickerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Language")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Language", selection: $viewModel.selectedSample) {
                    ForEach(CodeSamples.all) { sample in
                        Text(sample.name).tag(sample)
                    }
                }
                .pickerStyle(.menu)
            }

            HStack {
                Text("Theme")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Theme", selection: $viewModel.selectedTheme) {
                    ForEach(ShikiTheme.all, id: \.self) { theme in
                        Text(theme).tag(theme)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding()
        .onChange(of: viewModel.selectedSample) { _ in
            Task { await viewModel.highlight() }
        }
        .onChange(of: viewModel.selectedTheme) { _ in
            Task { await viewModel.highlight() }
        }
    }

    private var contentSection: some View {
        ZStack {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Highlighting...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let response):
                VStack(spacing: 0) {
                    CodeHighlightView(tokens: response.tokens)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .refreshable {
                            await viewModel.highlight()
                        }
                    Divider()
                    MetricsBar(
                        networkMs: viewModel.elapsedMs,
                        serverMs: response.debug?.totalMs,
                        lines: response.tokens.count,
                        characters: response.tokens.flatMap { $0 }.reduce(0) { $0 + $1.text.count }
                    )
                }
            case .error(let error):
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task { await viewModel.highlight() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    #if canImport(UIKit)
    @MainActor
    private func shareImage(tokens: [[Token]]) -> Image {
        let view = CodeHighlightView(tokens: tokens)
            .padding()
            .background(.background)
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "photo")
    }
    #endif

    private func copyToClipboard(tokens: [[Token]]) {
        let text = tokens.map { line in line.map(\.text).joined() }.joined(separator: "\n")
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}
