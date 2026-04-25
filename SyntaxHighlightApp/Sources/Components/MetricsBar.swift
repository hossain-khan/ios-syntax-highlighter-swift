import SwiftUI

/// Compact bar displaying network time, server time, line count, and character count.
struct MetricsBar: View {
    let networkMs: Double?
    let serverMs: Double?
    let lines: Int
    let characters: Int

    var body: some View {
        HStack(spacing: 16) {
            if let networkMs {
                metricItem(icon: "network", label: "Network", value: String(format: "%.0f ms", networkMs))
            }
            if let serverMs {
                metricItem(icon: "server.rack", label: "Server", value: String(format: "%.1f ms", serverMs))
            }
            metricItem(icon: "text.alignleft", label: "Lines", value: "\(lines)")
            metricItem(icon: "character.cursor.ibeam", label: "Chars", value: "\(characters)")
        }
        .font(.caption)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func metricItem(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.medium)
        }
    }
}
