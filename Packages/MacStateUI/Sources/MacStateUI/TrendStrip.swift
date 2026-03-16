import SwiftUI

public struct TrendStrip: View {
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
        HStack(alignment: .bottom, spacing: 4) {
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
        let clampedValues = values.map { max($0, 0) }
        guard let maximumValue = clampedValues.max(), maximumValue > 0 else {
            return []
        }

        let divisor = maximumValue > 1 ? maximumValue : 1
        return clampedValues.map { min($0 / divisor, 1) }
    }
}
