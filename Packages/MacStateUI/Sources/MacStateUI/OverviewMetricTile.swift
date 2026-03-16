import SwiftUI

public struct OverviewMetricTile: View {
    private let title: String
    private let value: String
    private let detail: String?
    private let trendValues: [Double]
    private let tint: Color

    public init(
        _ title: String,
        value: String,
        detail: String? = nil,
        trendValues: [Double],
        tint: Color
    ) {
        self.title = title
        self.value = value
        self.detail = detail
        self.trendValues = trendValues
        self.tint = tint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(value)
                .font(.headline)
                .bold()
                .fixedSize(horizontal: false, vertical: true)

            if let detail, detail.isEmpty == false {
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            TrendStrip(values: trendValues, tint: tint)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: MetricCardStyle.cornerRadius, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .clipShape(.rect(cornerRadius: MetricCardStyle.cornerRadius))
    }
}
