import Foundation

enum TrendStripSampler {
    static func binnedNormalizedValues(
        from values: [Double],
        maximumSampleCount: Int
    ) -> [Double] {
        let clampedValues = values.map { max($0, 0) }
        guard clampedValues.isEmpty == false else {
            return []
        }

        let boundedSampleCount = max(1, maximumSampleCount)
        let sampledValues = reducedValues(
            from: clampedValues,
            maximumSampleCount: boundedSampleCount
        )

        guard let maximumValue = sampledValues.max(), maximumValue > 0 else {
            return []
        }

        let divisor = max(maximumValue, 1)
        return sampledValues.map { min($0 / divisor, 1) }
    }

    private static func reducedValues(
        from values: [Double],
        maximumSampleCount: Int
    ) -> [Double] {
        guard values.count > maximumSampleCount else {
            return values
        }

        return (0..<maximumSampleCount).compactMap { index in
            let lowerBound = Int(
                floor(Double(index) * Double(values.count) / Double(maximumSampleCount))
            )
            let upperBound = Int(
                floor(Double(index + 1) * Double(values.count) / Double(maximumSampleCount))
            )

            guard lowerBound < upperBound else {
                return nil
            }

            let bucket = values[lowerBound..<upperBound]
            let total = bucket.reduce(0, +)
            return total / Double(bucket.count)
        }
    }
}
