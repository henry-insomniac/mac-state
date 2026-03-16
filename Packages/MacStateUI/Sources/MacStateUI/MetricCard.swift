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
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: MetricCardStyle.cornerRadius, style: .continuous)
                .fill(Color.secondary.opacity(0.12))
        )
    }
}
