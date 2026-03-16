import SwiftUI

public struct MetricCard<Content: View>: View {
    private let title: String
    private let content: Content

    public init(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: MetricCardStyle.cornerRadius, style: .continuous)
                .fill(Color.secondary.opacity(0.12))
        )
        .clipShape(
            RoundedRectangle(cornerRadius: MetricCardStyle.cornerRadius, style: .continuous)
        )
    }
}
