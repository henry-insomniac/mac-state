import SwiftUI

public struct TrendStrip: View {
    private enum Layout {
        static let maximumVisibleSamples = 32
        static let barSpacing: CGFloat = 2
    }

    private let values: [Double]
    private let tint: Color

    public init(
        values: [Double],
        tint: Color
    ) {
        self.values = values
        self.tint = tint
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: Layout.barSpacing) {
            if normalizedValues.isEmpty {
                RoundedRectangle(cornerRadius: MetricCardStyle.cornerRadius, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .frame(height: 18)
            } else {
                ForEach(normalizedValues.indices, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(tint.opacity(0.2 + (normalizedValues[index] * 0.8)))
                        .frame(maxWidth: .infinity)
                        .frame(height: 6 + (normalizedValues[index] * 22))
                }
            }
        }
        .frame(height: 28)
    }

    private var normalizedValues: [Double] {
        TrendStripSampler.binnedNormalizedValues(
            from: values,
            maximumSampleCount: Layout.maximumVisibleSamples
        )
    }
}
