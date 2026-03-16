import SwiftUI

public struct CollapsibleMetricCard<Summary: View, Details: View>: View {
    private let title: String
    @Binding private var isExpanded: Bool
    private let expandAccessibilityLabel: String
    private let collapseAccessibilityLabel: String
    private let summary: Summary
    private let details: Details

    public init(
        _ title: String,
        isExpanded: Binding<Bool>,
        expandAccessibilityLabel: String,
        collapseAccessibilityLabel: String,
        @ViewBuilder summary: () -> Summary,
        @ViewBuilder details: () -> Details
    ) {
        self.title = title
        _isExpanded = isExpanded
        self.expandAccessibilityLabel = expandAccessibilityLabel
        self.collapseAccessibilityLabel = collapseAccessibilityLabel
        self.summary = summary()
        self.details = details()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    summary
                }

                Spacer(minLength: 12)

                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .imageScale(.large)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? collapseAccessibilityLabel : expandAccessibilityLabel)
            }

            if isExpanded {
                Divider()

                details
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: MetricCardStyle.cornerRadius, style: .continuous)
                .fill(Color.secondary.opacity(0.12))
        )
        .clipShape(.rect(cornerRadius: MetricCardStyle.cornerRadius))
    }
}
