import SwiftUI
import ShikiTokenSDK

/// Dual-theme highlighting with side-by-side toggle and live dark/light switching.
struct DualThemeScreen: View {
    @StateObject private var viewModel: DualThemeViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showSideBySide = false

    init(client: ShikiClient) {
        _viewModel = StateObject(wrappedValue: DualThemeViewModel(client: client))
    }

    var body: some View {
        VStack(spacing: 0) {
            pickerSection
            Divider()
            contentSection
        }
        .navigationTitle("Dual Theme")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showSideBySide.toggle()
                } label: {
                    Image(systemName: showSideBySide ? "rectangle" : "rectangle.split.2x1")
                }
            }
            if let response = viewModel.state.value {
                ToolbarItem(placement: .automatic) {
                    Button {
                        copyToClipboard(tokens: response.tokens)
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
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
                Text("Dark Theme")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Dark", selection: $viewModel.darkTheme) {
                    ForEach(ShikiTheme.all, id: \.self) { theme in
                        Text(theme).tag(theme)
                    }
                }
                .pickerStyle(.menu)
            }

            HStack {
                Text("Light Theme")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Light", selection: $viewModel.lightTheme) {
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
        .onChange(of: viewModel.darkTheme) { _ in
            Task { await viewModel.highlight() }
        }
        .onChange(of: viewModel.lightTheme) { _ in
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
                ScrollView {
                    VStack(spacing: 0) {
                        if showSideBySide {
                            sideBySideView(tokens: response.tokens)
                        } else {
                            CodeHighlightView(tokens: response.tokens)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                        Divider()
                        HStack {
                            Text(colorScheme == .dark ? "Dark mode" : "Light mode")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        MetricsBar(
                            networkMs: viewModel.elapsedMs,
                            serverMs: response.debug?.totalMs,
                            lines: response.tokens.count,
                            characters: response.tokens.flatMap { $0 }.reduce(0) { $0 + $1.text.count }
                        )
                    }
                }
                .refreshable {
                    await viewModel.highlight()
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

    private func sideBySideView(tokens: [[DualToken]]) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dark")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                CodeHighlightView(tokens: tokens)
                    .environment(\.colorScheme, .dark)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(maxWidth: .infinity)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Light")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                CodeHighlightView(tokens: tokens)
                    .environment(\.colorScheme, .light)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }

    private func copyToClipboard(tokens: [[DualToken]]) {
        let text = tokens.map { line in line.map(\.text).joined() }.joined(separator: "\n")
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}
