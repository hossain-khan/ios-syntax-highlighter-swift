import SwiftUI
import ShikiTokenSDK

/// Navigation hub with cards linking to each demo screen.
struct HomeScreen: View {
    let client: ShikiClient

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    cardsSection
                }
                .padding()
            }
            .navigationTitle("Shiki Highlighter")
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            Text("Syntax Highlighting\npowered by Shiki")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("TextMate grammars via server-side tokenization")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical)
    }

    private var cardsSection: some View {
        VStack(spacing: 12) {
            NavigationLink {
                HighlightScreen(client: client)
            } label: {
                cardView(
                    icon: "paintbrush",
                    title: "Single Theme",
                    description: "Highlight code with one color theme"
                )
            }

            NavigationLink {
                DualThemeScreen(client: client)
            } label: {
                cardView(
                    icon: "circle.lefthalf.filled",
                    title: "Dual Theme",
                    description: "Dark & light tokens in one request — instant mode switching"
                )
            }

            NavigationLink {
                SemanticScreen(client: client)
            } label: {
                cardView(
                    icon: "tag",
                    title: "Semantic",
                    description: "Token types instead of colors — bring your own palette"
                )
            }

            NavigationLink {
                LanguageExplorerScreen(client: client)
            } label: {
                cardView(
                    icon: "globe",
                    title: "Language Explorer",
                    description: "Browse all supported languages and themes"
                )
            }
        }
    }

    private func cardView(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
