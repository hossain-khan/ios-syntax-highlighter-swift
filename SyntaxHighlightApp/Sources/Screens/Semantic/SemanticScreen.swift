import SwiftUI
import ShikiTokenSDK

/// Semantic highlighting with token type legend and configurable color palette.
struct SemanticScreen: View {
    @StateObject private var viewModel: SemanticViewModel

    init(client: ShikiClient) {
        _viewModel = StateObject(wrappedValue: SemanticViewModel(client: client))
    }

    var body: some View {
        VStack(spacing: 0) {
            pickerSection
            Divider()
            contentSection
        }
        .navigationTitle("Semantic")
        .task {
            await viewModel.highlight()
        }
    }

    private var pickerSection: some View {
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
        .padding()
        .onChange(of: viewModel.selectedSample) { _ in
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
                    CodeHighlightView(tokens: response.tokens, colorMapping: viewModel.colorMapping)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    Divider()
                    tokenLegend(tokenTypes: response.tokenTypes)
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

    private func tokenLegend(tokenTypes: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tokenTypes, id: \.self) { typeString in
                    if let tokenType = TokenType(rawValue: typeString) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(viewModel.colorMapping[tokenType] ?? .primary)
                                .frame(width: 8, height: 8)
                            Text(typeString)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }
}
